require 'sequel'

Sequel.migration do
  up do
    add_column :accounts, :is_test, FalseClass
  end

  down do
    drop_column :accounts, :is_test
  end
end