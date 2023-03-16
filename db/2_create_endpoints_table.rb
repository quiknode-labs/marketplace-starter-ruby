require 'sequel'

Sequel.migration do
  up do
    create_table(:endpoints) do
      primary_key :id
      Integer :account_id, null: false
      String :endpoint_id, null: false
      String :wss_url, null: false
      String :http_url, null: false
      String :chain, null: false
      String :network, null: false
    end
  end

  down do
    drop_table(:endpoints)
  end
end