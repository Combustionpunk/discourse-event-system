# frozen_string_literal: true

class CreateDesUserTransponders < ActiveRecord::Migration[7.0]
  def up
    create_table :des_user_transponders do |t|
      t.integer :user_id, null: false
      t.integer :shortcode, null: false
      t.string :long_code, null: false
      t.string :notes
      t.timestamps
    end
    add_index :des_user_transponders, [:user_id, :shortcode], unique: true
    add_index :des_user_transponders, [:user_id, :long_code], unique: true

    # Import existing transponders from car records
    # For each user, collect distinct transponder long codes from their cars
    execute <<-SQL
      INSERT INTO des_user_transponders (user_id, shortcode, long_code, created_at, updated_at)
      SELECT
        user_id,
        ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY MIN(id)) AS shortcode,
        transponder_number AS long_code,
        NOW(),
        NOW()
      FROM des_user_cars
      WHERE transponder_number IS NOT NULL
        AND transponder_number != ''
        AND transponder_number != '0'
      GROUP BY user_id, transponder_number
    SQL
  end

  def down
    drop_table :des_user_transponders
  end
end
