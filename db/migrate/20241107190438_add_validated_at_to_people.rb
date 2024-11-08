class AddValidatedAtToPeople < ActiveRecord::Migration[7.2]
  def change
    add_column :people, :validated_at, :datetime
  end
end
