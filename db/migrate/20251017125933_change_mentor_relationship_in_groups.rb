class ChangeMentorRelationshipInGroups < ActiveRecord::Migration[7.2]
  def change
    add_column :groups, :mentor_id, :integer
    add_index :groups, :mentor_id
  end
end
