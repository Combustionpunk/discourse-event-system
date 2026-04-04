class CreatePositions < ActiveRecord::Migration[7.0]
  def change
    create_table :des_positions do |t|
      t.string :name, null: false
      t.boolean :is_admin, default: false
      t.timestamps
    end
  end
end
