# frozen_string_literal: true

class AddLogoToManufacturers < ActiveRecord::Migration[7.0]
  def change
    add_column :des_manufacturers, :logo_upload_id, :integer
  end
end
