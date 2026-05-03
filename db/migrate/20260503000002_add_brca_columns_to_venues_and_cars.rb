# frozen_string_literal: true

class AddBrcaColumnsToVenuesAndCars < ActiveRecord::Migration[7.0]
  def up
    unless column_exists?(:des_venues, :source)
      add_column :des_venues, :source, :string, default: 'manual'
    end

    unless column_exists?(:des_venues, :is_stub)
      add_column :des_venues, :is_stub, :boolean, default: false
    end

    unless column_exists?(:des_venues, :claimed_organisation_id)
      add_column :des_venues, :claimed_organisation_id, :integer
    end

    unless column_exists?(:des_venues, :claim_status)
      add_column :des_venues, :claim_status, :string, default: 'unclaimed'
    end

    unless column_exists?(:des_car_models, :power_type)
      add_column :des_car_models, :power_type, :string, default: 'electric'
    end
  end

  def down
    remove_column :des_car_models, :power_type if column_exists?(:des_car_models, :power_type)
    remove_column :des_venues, :claim_status if column_exists?(:des_venues, :claim_status)
    remove_column :des_venues, :claimed_organisation_id if column_exists?(:des_venues, :claimed_organisation_id)
    remove_column :des_venues, :is_stub if column_exists?(:des_venues, :is_stub)
    remove_column :des_venues, :source if column_exists?(:des_venues, :source)
  end
end
