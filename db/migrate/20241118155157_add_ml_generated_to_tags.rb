class AddMlGeneratedToTags < ActiveRecord::Migration[7.2]
  def change
    add_column :tags, :ml_generated, :boolean, default: false
  end
end