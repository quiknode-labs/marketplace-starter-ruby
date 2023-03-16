require 'sequel'

Sequel.migration do
  up do
    create_table(:accounts) do
      primary_key :id
      String :quicknode_id, null: false
      String :plan_slug, null: false
    end
  end

  down do
    drop_table(:accounts)
  end
end