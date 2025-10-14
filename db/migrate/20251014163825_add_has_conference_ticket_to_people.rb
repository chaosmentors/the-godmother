class AddHasConferenceTicketToPeople < ActiveRecord::Migration[7.2]
  def change
    add_column :people, :has_conference_ticket, :boolean, default: nil, null: true
  end
end
