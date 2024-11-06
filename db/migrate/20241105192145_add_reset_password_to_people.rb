class AddResetPasswordToPeople < ActiveRecord::Migration[7.2]
  def change
    add_column :people, :reset_password_token, :string
    add_column :people, :reset_password_sent_at, :datetime
  end
end
