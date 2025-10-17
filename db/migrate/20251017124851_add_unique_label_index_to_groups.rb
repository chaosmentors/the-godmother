class AddUniqueLabelIndexToGroups < ActiveRecord::Migration[7.2]
  def change
    add_index :groups, :label, unique: true
  end
end
