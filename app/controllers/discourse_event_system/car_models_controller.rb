# frozen_string_literal: true

module DiscourseEventSystem
  class CarModelsController < ApplicationController
    def index
      manufacturers = DesManufacturer.includes(:logo).all.order(:name)
      models = DesCarModel.includes(:manufacturer).order(:name)

      render json: {
        manufacturers: manufacturers.map { |m| serialize_manufacturer(m) },
        models_by_manufacturer: manufacturers.map { |mfr|
          mfr_models = models.select { |m| m.manufacturer_id == mfr.id }
          next if mfr_models.empty?
          {
            manufacturer_id: mfr.id,
            manufacturer_name: mfr.name,
            manufacturer_status: mfr.status,
            manufacturer_logo_url: mfr.logo&.url,
            models: mfr_models.map { |m| serialize_model(m) }
          }
        }.compact
      }
    end

    def suggest_manufacturer
      ensure_logged_in
      manufacturer = DesManufacturer.create!(
        name: params[:name].to_s.strip,
        status: 'pending',
        created_by: current_user.id
      )
      render json: serialize_manufacturer(manufacturer), status: :created
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    private

    def serialize_manufacturer(m)
      {
        id: m.id,
        name: m.name,
        status: m.status,
        logo_upload_id: m.logo_upload_id,
        logo_url: m.logo&.url
      }
    end

    def serialize_model(m)
      {
        id: m.id,
        name: m.name,
        manufacturer_id: m.manufacturer_id,
        manufacturer_name: m.manufacturer&.name,
        year_released: m.year_released,
        driveline: m.driveline,
        scale: m.scale,
        chassis_type: m.chassis_type,
        status: m.status,
        created_by: m.creator&.username
      }
    end
  end
end
