class CreateEmails < ActiveRecord::Migration[7.2]
  def change
    create_table :emails do |t|
      t.references :person, null: true, foreign_key: true
      t.string :message_id, null: false
      t.string :in_reply_to
      t.string :from_address, null: false
      t.string :to_addresses
      t.string :subject
      t.text :body_plain
      t.text :body_html
      t.datetime :sent_at
      t.string :direction
      t.string :imap_uid
      t.string :mailbox

      t.timestamps
    end

    add_index :emails, :message_id, unique: true
    add_index :emails, :from_address
    add_index :emails, :sent_at
    add_index :emails, :direction
    add_index :emails, [:mailbox, :imap_uid]
  end
end
