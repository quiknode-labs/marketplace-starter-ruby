require 'sequel'

Sequel.migration do
  up do
    add_column :endpoints, :is_test, FalseClass
  end

  down do
    drop_column :endpoints, :is_test
  end
end