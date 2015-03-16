class User < ActiveRecord::Base
  self.table_name = "users_schema.users"

  validates_presence_of :email, :first_name, :last_name
end
