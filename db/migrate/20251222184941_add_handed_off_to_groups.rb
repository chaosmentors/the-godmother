class AddHandedOffToGroups < ActiveRecord::Migration[7.2]
  def change
    add_column :groups, :handed_off, :boolean, default: false
  end
end
