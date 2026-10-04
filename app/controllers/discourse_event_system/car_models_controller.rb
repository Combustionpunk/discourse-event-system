# frozen_string_literal: true

module DiscourseEventSystem
  class CarModelsController < ApplicationController
    def index
      manufacturers = DesManufacturer.includes(:logo).all.order(:name)
      models = DesCarModel.includes(:manufacturer, :creator, box_art: :optimized_images).order(:name)

      render json: {
        image_suggestions: image_suggestions_payload,
        my_pending_box_art_model_ids: my_pending_box_art_model_ids,
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

    def suggest_box_art
      ensure_logged_in
      model = DesCarModel.find(params[:id])
      upload_id = DesCarModel.box_art_upload_id_for(params[:upload_id], current_user)
      raise Discourse::InvalidParameters.new(:upload_id) if upload_id.blank?

      if current_user.admin?
        model.update!(box_art_upload_id: upload_id)
        return render json: { applied: true }
      end

      if model.image_suggestions.pending.exists?(user_id: current_user.id)
        return render_json_error(I18n.t("discourse_event_system.box_art.already_pending"), status: 409)
      end

      RateLimiter.new(current_user, "des-suggest-box-art", 10, 1.hour).performed!
      suggestion = model.image_suggestions.create!(upload_id: upload_id, user: current_user)
      render json: { applied: false, suggestion_id: suggestion.id }, status: :created
    rescue ActiveRecord::RecordInvalid => e
      render_json_error(e.record.errors.full_messages.join(", "))
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

    def image_suggestions_payload
      return [] unless current_user&.admin?
      DesCarModelImageSuggestion
        .pending
        .includes(:user, :upload, car_model: :manufacturer)
        .order(:created_at)
        .map do |suggestion|
          {
            id: suggestion.id,
            car_model_id: suggestion.car_model_id,
            car_model_name: suggestion.car_model.name,
            manufacturer_name: suggestion.car_model.manufacturer&.name,
            suggested_by: suggestion.user&.username,
            image_url: suggestion.upload&.url,
          }
        end
    end

    def my_pending_box_art_model_ids
      return [] if current_user.blank? || current_user.admin?
      DesCarModelImageSuggestion.pending.where(user_id: current_user.id).pluck(:car_model_id)
    end

    def serialize_manufacturer(m)
      {
        id: m.id,
        name: m.name,
        status: m.status,
        logo_upload_id: m.logo&.id,
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
        power_type: m.power_type,
        status: m.status,
        created_by: m.creator&.username,
        box_art_upload_id: m.box_art&.id,
        box_art_url: m.box_art_thumbnail_url,
        box_art_full_url: m.box_art&.url,
        box_art_width: m.box_art&.width,
        box_art_height: m.box_art&.height
      }
    end
  end
end
