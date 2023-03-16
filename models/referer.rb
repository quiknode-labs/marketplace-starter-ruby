require 'sequel'

class Referer < Sequel::Model
  many_to_one :endpoint
end