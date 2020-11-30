class AddIsGodmotherToPeople < ActiveRecord::Migration[5.2]
  def change
    add_column :people, :isgodmother, :boolean
  end
end
