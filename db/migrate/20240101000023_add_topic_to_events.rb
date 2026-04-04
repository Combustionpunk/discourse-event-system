class AddTopicToEvents < ActiveRecord::Migration[7.0]
  def change
    add_column :des_events, :topic_id, :integer
    add_column :des_events, :category_id, :integer
    add_index :des_events, :topic_id, unique: true
    add_index :des_events, :category_id
  end
end
