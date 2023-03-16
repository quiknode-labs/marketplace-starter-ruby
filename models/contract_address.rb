require 'sequel'

class ContractAddress < Sequel::Model
  many_to_one :endpoint
end