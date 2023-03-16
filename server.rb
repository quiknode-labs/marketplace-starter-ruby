# frozen_string_literal: true

require 'jwt'
require 'json'
require 'redis'
require 'sinatra'
require 'sequel'
require 'dotenv/load'
require 'rack/auth/basic'

# Autoloader: extend for more cool things
DB = Sequel.connect(ENV['DB_URL'])
%w{models lib}.each {|dir| Dir.glob("#{dir}/*.rb", &method(:require_relative))}

set :default_content_type, :json
enable :sessions

$redis = Redis.new

helpers do
  def protected!
    return if authorized?
    headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
    halt 401, "Not authorized\n"
  end

  def authorized?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? and @auth.basic? and @auth.credentials and @auth.credentials == [ENV.fetch("AUTH_USERNAME"), ENV.fetch("AUTH_PASSWORD")]
  end
end


# Add a get method so that we don't reveal Sinatra basic page
get '/' do
  content_type :html
  @accounts = Account.where(deprovisioned_at: nil).invert.all
  erb :index
end

post '/provision' do
  protected!
  payload = JSON.parse(request.body.read)
  logger.info "PROVISION #{payload['quicknode-id']} #{payload['endpoint-id']}"

  existing_accounts = Account.first(quicknode_id: payload['quicknode-id'], plan_slug: payload['plan'])
  endpoint_info = {
    endpoint_id: payload['endpoint-id'],
    wss_url: payload['wss-url'],
    http_url: payload['http-url'],
    chain: payload['chain'],
    network: payload['network'],
    is_test: !!request.env['HTTP_X_QN_TESTING']
  }

  if !existing_accounts.nil?
    account = existing_accounts
    existing_endpoints = account.endpoints_dataset.where(endpoint_id: payload['endpoint-id']).all
    if existing_endpoints.size > 0
      existing_endpoints.each do |endpoint|
        endpoint.update(endpoint_info)
        endpoint.add_referers(payload['referers'])
        endpoint.add_contract_addresses(payload['contract_addresses'])
      end
    else
      endpoint = account.add_endpoint(endpoint_info)
      endpoint.add_referers(payload['referers'])
      endpoint.add_contract_addresses(payload['contract_addresses'])
    end
  else
    account = Account.create(quicknode_id: payload['quicknode-id'], plan_slug: payload['plan'], is_test: !!request.env['HTTP_X_QN_TESTING'])
    endpoint = account.add_endpoint(endpoint_info)
    endpoint.add_referers(payload['referers'])
    endpoint.add_contract_addresses(payload['contract_addresses'])
  end

  {
    "status": "success",
    # "dashboard_url": nil,
    # "access_url": nil
    # Only set these if you have features for them
    "dashboard-url": "http://#{ENV['host']}/dash",
    "access-url": "http://#{ENV['host']}/api/#{payload['quicknode-id']}.json"
  }.to_json
end

put '/update' do
  protected!
  payload = JSON.parse(request.body.read)
  logger.info "UPDATE #{payload['quicknode-id']} #{payload['endpoint-id']}"

  account = Account.first(quicknode_id: payload['quicknode-id'])
  unless !account.nil?
    logger.info "[WARNING] Account #{payload['quicknode-id']} is not provisioned yet"
    return {
      "status": "error",
      "message": "Unable to find account: #{payload['quicknode-id']}"
    }.to_json
  end

  endpoint = account.endpoints_dataset.first(endpoint_id: payload['endpoint-id'])
  unless !endpoint.nil?
    logger.info "[WARNING] Endpoint #{payload['endpoint-id']} is not provisioned yet"
  end

  endpoint_info = {
    endpoint_id: payload['endpoint-id'],
    wss_url: payload['wss-url'],
    http_url: payload['http-url'],
    chain: payload['chain'],
    network: payload['network'],
  }
  endpoint = account.add_endpoint(endpoint_info)
  endpoint.add_referers(payload['referers'])
  endpoint.add_contract_addresses(payload['contract_addresses'])

  {
    "status": "success",
    "dashboard_url": nil,
    "access_url": nil
    # Only set these if you have features for them
    # "dashboard_url": "http://#{ENV['host']}/dash",
    # "access_url": "http://#{ENV['host']}/api/#{payload['quicknode-id']}.json"
  }.to_json
end

delete '/deprovision' do
  protected!
  payload = JSON.parse(request.body.read)
  logger.info "DEPROVISION #{payload['quicknode-id']} #{payload['endpoint-id']}"

  account = Account.first(quicknode_id:  payload['quicknode-id'])
  unless !account.nil?
    logger.info "[WARNING] Account #{payload['quicknode-id']} is not provisioned yet"
  end

  deprovisioned_at = DateTime.strptime(payload['deprovision-at'], '%s')
  account.update(deprovisioned_at: deprovisioned_at)
  account.endpoints_dataset.all.each do |endpoint|
    endpoint.update(deprovisioned_at: deprovisioned_at)
  end

  {
    "status": "success"
  }.to_json
end

delete '/deactivate_endpoint' do
  protected!
  payload = JSON.parse(request.body.read)
  logger.info "DEACTIVATE ENDPOINT #{payload['quicknode-id']} #{payload['endpoint-id']}"
  logger.info payload

  account = Account.first(quicknode_id:  payload['quicknode-id'])
  unless !account.nil?
    logger.info "[WARNING] Account #{payload['quicknode-id']} is not provisioned yet"
  end

  endpoint = account.endpoints_dataset.first(endpoint_id: payload['endpoint-id'])
  unless !endpoint.nil?
    logger.info "[WARNING] Endpoint #{payload['endpoint-id']} is not provisioned yet"
  end

  deprovisioned_at = DateTime.now
  endpoint.update(deprovisioned_at: deprovisioned_at)

  {
    "status": "success"
  }.to_json
end

get "/dash" do
  content_type :html

  token = params['jwt']
  begin

    decoded_tokens = JWT.decode token, ENV.fetch("JWT_SECRET"), true
    @decoded_token = decoded_tokens.first
    logger.info "[DASH] decoded_token: #{@decoded_token}"
    session[:user_id] = @decoded_token["quicknode_id"]
    session[:email] = @decoded_token["email"]
  rescue JWT::VerificationError
    @error = 'forged or missing JWT'
  rescue JWT::DecodeError
    @error = "forged or missing JWT"
  end

  logger.info "DASHBOARD for #{@decoded_token["quicknode_id"]}"

  account = Account.first(quicknode_id: @decoded_token["quicknode_id"], deprovisioned_at: nil)
  @account_is_active = !account.nil?
  @endpoints = account.endpoints_dataset.all

  erb :dash
end

get "/api/:id" do
  val = $redis.get("starter_#{params['id']}")
  if val
    { message: 'You thought it was that easy to predict the future?' }.to_json
  else
    { message: 'Denied!' }.to_json
  end
end

get "/healthcheck" do
  Account.all # here to make sure db is up
  "OK"
end

post "/rpc" do
  quicknode_id = request.env['HTTP_X_QUICKNODE_ID']
  endpoint_id = request.env['HTTP_X_INSTANCE_ID']
  chain = request.env['HTTP_X_QN_CHAIN']
  network = request.env['HTTP_X_QN_NETWORK']
  logger.info "[RPC] X-QUICKNODE-ID = #{quicknode_id}, ENDPOINT ID = #{endpoint_id}"
  account = Account.first(quicknode_id: quicknode_id, deprovisioned_at: nil)

  return {
    "id": 1,
    "error": {
      "code":-32001,
      "message":"Unauthenticated request"
    },
    "jsonrpc":"2.0"
  }.to_json if account.nil?

  endpoint = account.endpoints_dataset.first(endpoint_id: endpoint_id, deprovisioned_at: nil)
  return {
    "id": 1,
    "error": {
      "code":-32001,
      "message":"Endpoint is not provisioned"
    },
    "jsonrpc":"2.0"
  }.to_json if endpoint.nil?

  payload = JSON.parse(request.body.read)
  if payload.is_a? Array
    response = payload.map do |item|
      JSONRPCHandler::handle_method_call(item, chain, network)
    end
  else
    response = JSONRPCHandler::handle_method_call(payload, chain, network)
  end
  response.to_json
end
