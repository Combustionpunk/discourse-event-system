class CreateEventWaitlist < ActiveRecord::Migration[7.0]
  def change
    create_table :des_event_waitlist do |t|
      t.integer :event_id, null: false
      t.integer :event_class_id, null: false
      t.integer :user_id, null: false
      t.integer :position, null: false
      t.string :status, default: 'waiting'
      t.timestamps
    end

    add_index :des_event_waitlist, :event_id
    add_index :des_event_waitlist, :user_id
    add_index :des_event_waitlist, [:event_class_id, :user_id],
              unique: true,
              name: 'unique_waitlist_entry'
  end
end
