require 'httparty'
BASE_URLS = {
  'bitcoin' => {
    'btc-testnet' => '',
    'btc' => ''
  },
  'ethereum' => {
    'mainnet' => ''
  }
}
REQUEST_CONFIG = {
  'bb_getAddress' => {
    method: 'get',
    base_path: '/api/v2/address/:address',
    named_segment_replacements: {
      ':address' => 0
    },
    query_string: {
      'page' => [1, 'page'],
      'pageSize' => [1, 'size'],
      'from' => [1, 'fromHeight'],
      'to' => [1, 'toHeight'],
      'details' => [1, 'details'],
      'secondary' => [1, 'secondary'],
    }
  },
  'bb_getXPUB' => {
    method: 'get',
    base_path: '/api/v2/xpub/:xpub',
    named_segment_replacements: {
      ':xpub' => 0
    },
    query_string: {
      'page' => [1, 'page'],
      'pageSize' => [1, 'size'],
      'from' => [1, 'fromHeight'],
      'to' => [1, 'toHeight'],
      'details' => [1, 'details'],
      'tokens' => [1, 'tokens'],
      'secondary' => [1, 'secondary']
    }
  },
  'bb_getUTXOs' => {
    method: 'get',
    base_path: '/api/v2/utxo/:address_or_xpub',
    named_segment_replacements: {
      ':address_or_xpub' => 0
    },
    query_string: {
      'confirmed' => [1, 'confirmed']
    }
  }
}

module JSONRPCHandler
  def self.build_url(payload, chain, network)
    info = REQUEST_CONFIG[payload['method']]

    hostname = BASE_URLS[chain][network]
    populated_path = info[:base_path]
    info[:named_segment_replacements].each do |segment, populate_from|
      populated_path = populated_path.gsub(segment, payload['params'].send('[]', populate_from))
    end

    hostname + populated_path
  end

  def self.build_qs(payload)
    info = REQUEST_CONFIG[payload['method']]
    qs = {}
    info[:query_string].each do |qs_arg, rpc_arg_path|
      if payload['params'].dig(*rpc_arg_path)
        qs[qs_arg] = payload['params'].dig(*rpc_arg_path)
      end
    end

    qs
  end

  def self.build_args(payload, chain, network)
    info = REQUEST_CONFIG[payload['method']]
    url = build_url(payload, chain, network)
    qs = build_qs(payload)

    [info[:method], url, { query: qs }]
  end

  def self.handle_method_call(method_hash, chain, network)
    args = build_args(method_hash, chain, network)
    args[-1][:verify] = false

    begin
      response = HTTParty.send(*args)
      {
        "id": method_hash['id'],
        "result": response.parsed_response,
        "jsonrpc":"2.0"
      }
    rescue
      {
        "id": 1,
        "error": {
          "code":-31000,
          "message":"Generic error"
        },
        "jsonrpc":"2.0"
      }
    end
  end
end
