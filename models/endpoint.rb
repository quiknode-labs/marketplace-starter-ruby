require 'sequel'

class Endpoint < Sequel::Model
  many_to_one :account
  one_to_many :referers
  one_to_many :contract_addresses

  def add_referers(list)
    list.each do |referer|
      self.add_referer(referer: referer)
    end 
  end

  def add_contract_addresses(list)
    list.each do |address|
      self.add_contract_address(address: address)
    end
  end
end