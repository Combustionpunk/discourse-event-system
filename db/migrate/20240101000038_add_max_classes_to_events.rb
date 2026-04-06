class AddMaxClassesToEvents < ActiveRecord::Migration[7.0]
  def change
    add_column :des_events, :max_classes_per_booking, :integer, null: true
  end
end
