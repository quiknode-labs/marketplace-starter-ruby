require 'sequel'

class Account < Sequel::Model
  one_to_many :endpoints 
end