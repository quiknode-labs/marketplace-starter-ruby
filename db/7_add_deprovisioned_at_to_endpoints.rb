require 'sequel'

Sequel.migration do
  up do
    add_column :endpoints, :deprovisioned_at, DateTime
  end

  down do
    drop_column :endpoints, :deprovisioned_at
  end
end