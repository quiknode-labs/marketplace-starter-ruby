require 'sequel'

Sequel.migration do
  up do
    add_column :accounts, :deprovisioned_at, DateTime
  end

  down do
    drop_column :accounts, :deprovisioned_at
  end
end