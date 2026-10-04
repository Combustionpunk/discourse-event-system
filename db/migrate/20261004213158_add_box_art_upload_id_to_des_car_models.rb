# frozen_string_literal: true

class AddBoxArtUploadIdToDesCarModels < ActiveRecord::Migration[8.1]
  def change
    add_column :des_car_models, :box_art_upload_id, :integer
  end
end
