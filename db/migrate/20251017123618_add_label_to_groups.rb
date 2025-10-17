class AddLabelToGroups < ActiveRecord::Migration[7.2]
  def change
    add_column :groups, :label, :string
  end
end
