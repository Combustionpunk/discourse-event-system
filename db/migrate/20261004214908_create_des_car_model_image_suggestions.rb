# frozen_string_literal: true

class CreateDesCarModelImageSuggestions < ActiveRecord::Migration[8.1]
  def change
    create_table :des_car_model_image_suggestions do |t|
      t.integer :car_model_id, null: false
      t.integer :upload_id, null: false
      t.integer :user_id, null: false
      t.string :status, null: false, default: "pending"
      t.timestamps
    end

    add_index :des_car_model_image_suggestions, %i[car_model_id status]
    add_index :des_car_model_image_suggestions,
              %i[car_model_id user_id],
              unique: true,
              where: "status = 'pending'",
              name: "idx_des_car_model_image_suggestions_one_pending_per_user"
  end
end
