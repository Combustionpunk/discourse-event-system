# frozen_string_literal: true

class AddCafeToVenues < ActiveRecord::Migration[7.0]
  def change
    add_column :des_venues, :has_cafe, :boolean, default: false
  end
end
