require 'sequel'

Sequel.migration do
  up do
    create_table(:contract_addresses) do
      primary_key :id
      Integer :endpoint_id, null: false
      String :address, null: false
    end
  end

  down do
    drop_table(:contract_addresses)
  end
end
