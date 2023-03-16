require 'sequel'

Sequel.migration do
  up do
    create_table(:requests) do
      primary_key :id
      foreign_key :endpoint_id, :endpoints
      String :ip, null: false
      String :request_body, null: false
      String :response_body, null: false
      Integer :response_code
      DateTime :created_at
    end
  end

  down do
    drop_table(:requests)
  end
end