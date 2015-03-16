class CreateUsers < ActiveRecord::Migration
  def up
    execute "CREATE SCHEMA users_schema"
    create_table "users_schema.users" do |t|
      t.string :email
      t.string :first_name
      t.string :last_name

      t.timestamps null: false
    end
  end

  def down
    drop_table "users_schema.users"
    execute "DROP SCHEMA users_schema"
  end
end
