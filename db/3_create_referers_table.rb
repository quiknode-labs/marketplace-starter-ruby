require 'sequel'

Sequel.migration do
  up do
    create_table(:referers) do
      primary_key :id
      Integer :endpoint_id, null: false
      String :referer, null: false
    end
  end

  down do
    drop_table(:referers)
  end
end
