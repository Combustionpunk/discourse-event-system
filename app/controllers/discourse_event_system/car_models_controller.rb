# frozen_string_literal: true

module DiscourseEventSystem
  class CarModelsController < ApplicationController
    requires_plugin PLUGIN_NAME

    skip_before_action :check_xhr, only: :page
    before_action :ensure_logged_in, only: %i[suggest_box_art suggest_manufacturer]

    def index
      manufacturers = DesManufacturer.visible_to(guardian).includes(:logo).order(:name)
      models =
        DesCarModel
          .visible_to(guardian)
          .includes(:manufacturer, :creator, box_art: :optimized_images)
          .order(:name)
      @racer_counts =
        DesUserCar.active.where.not(car_model_id: nil).group(:car_model_id).distinct.count(:user_id)

      render json: {
        can_edit: guardian.can_edit_car_models?,
        image_suggestions: image_suggestions_payload,
        my_pending_box_art_model_ids: my_pending_box_art_model_ids,
        my_garage_model_ids: my_garage_model_ids,
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

    def show
      model = find_visible_model!
      @racer_counts = { model.id => racers_scope(model).distinct.count(:user_id) }
      in_garage = current_user.present? && racers_scope(model).exists?(user_id: current_user.id)

      render json: {
        model:
          serialize_model(model).merge(
            manufacturer_logo_url: model.manufacturer&.logo&.url,
            in_garage: in_garage,
          ),
        racers: current_user ? serialize_racers(model) : nil,
        my_pending_box_art:
          current_user.present? && !guardian.can_edit_car_models? &&
            model.image_suggestions.pending.exists?(user_id: current_user.id),
        eligible_classes: eligible_classes(model),
        can_edit: guardian.can_edit_car_models?,
        edit_options: guardian.can_edit_car_models? ? edit_options : nil,
      }
    end

    # Server-rendered shell for /car-models/:id so shared links get OpenGraph tags.
    def page
      @car_model = DesCarModel.includes(:manufacturer, box_art: :optimized_images).find_by(id: params[:id].to_i)
      @car_model = nil unless @car_model&.status == "approved"
      render "discourse_event_system/car_models/page"
    end

    def suggest_box_art
      model = find_visible_model!
      upload_id = DesCarModel.box_art_upload_id_for(params[:upload_id], current_user)
      raise Discourse::InvalidParameters.new(:upload_id) if upload_id.blank?

      if guardian.can_edit_car_models?
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
      manufacturer = DesManufacturer.create!(
        name: params[:name].to_s.strip,
        status: 'pending',
        created_by: current_user.id
      )
      render json: serialize_manufacturer(manufacturer), status: :created
    rescue ActiveRecord::RecordInvalid => e
      render_json_error(e.record.errors.full_messages.join(", "))
    end

    private

    def find_visible_model!
      model = DesCarModel.includes(:creator, manufacturer: :logo, box_art: :optimized_images).find_by(id: params[:id].to_i)
      raise Discourse::NotFound unless model&.visible_to?(guardian)
      model
    end

    def racers_scope(model)
      DesUserCar.active.where(car_model_id: model.id)
    end

    def serialize_racers(model)
      User
        .where(id: racers_scope(model).select(:user_id))
        .order(:username_lower)
        .map { |user| { id: user.id, username: user.username, avatar_template: user.avatar_template } }
    end

    # Reuses the booking eligibility check by asking it about an unsaved garage car of this model.
    def eligible_classes(model)
      car = DesUserCar.new(car_model: model, manufacturer: model.manufacturer)
      DesEventClassType
        .includes(:organisation)
        .order(:name)
        .select { |class_type| car.eligible_for_class?(class_type, class_type.organisation_id) }
        .map { |class_type| { id: class_type.id, name: class_type.name, organisation_name: class_type.organisation&.name } }
    end

    def edit_options
      {
        manufacturers: DesManufacturer.order(:name).pluck(:id, :name).map { |id, name| { id: id, name: name } },
        scales: DesScale.order(:position, :name).pluck(:name),
        chassis_types: DesChassisType.order(:position, :name).pluck(:name),
      }
    end

    def image_suggestions_payload
      return [] unless guardian.can_edit_car_models?
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

    def my_garage_model_ids
      return [] if current_user.blank?
      DesUserCar.active.where(user_id: current_user.id).where.not(car_model_id: nil).distinct.pluck(:car_model_id)
    end

    def my_pending_box_art_model_ids
      return [] if current_user.blank? || guardian.can_edit_car_models?
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

    # Who suggested a model is moderation context, but suggesters can see their own.
    def show_creator?(model)
      guardian.can_edit_car_models? || (current_user.present? && model.created_by == current_user.id)
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
        created_by: show_creator?(m) ? m.creator&.username : nil,
        created_at: m.created_at,
        racer_count: @racer_counts&.fetch(m.id, 0) || 0,
        box_art_upload_id: m.box_art&.id,
        box_art_url: m.box_art_thumbnail_url,
        box_art_full_url: m.box_art&.url,
        box_art_width: m.box_art&.width,
        box_art_height: m.box_art&.height
      }
    end
  end
end
