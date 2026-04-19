# frozen_string_literal: true

module DiscourseEventSystem
  class GarageController < ApplicationController
    before_action :ensure_logged_in, except: [:public_garage]

    def index
      cars = DesUserCar.where(user_id: current_user.id)
        .includes(:manufacturer, :car_model, :class_type)
        .active
      render json: {
        cars: serialize_cars(cars),
        manufacturers: DesManufacturer.where(status: ['approved', 'pending']).order(:name).map { |m| 
          { id: m.id, name: m.name, status: m.status }
        },
        class_types: DesEventClassType.all.order(:name).map { |ct| { id: ct.id, name: ct.name } }
      }
    end

    def public_garage
      user = User.find_by(username: params[:username])
      return render json: { cars: [] }, status: :not_found unless user
      cars = DesUserCar.where(user_id: user.id)
        .includes(:manufacturer, :car_model, :class_type)
        .active
        .select { |c| c.car_model.nil? || c.car_model.status == 'approved' }
      render json: {
        cars: cars.map { |c|
          {
            friendly_name: c.display_name,
            manufacturer: c.manufacturer&.name || 'Unknown',
            model: c.car_model&.name || c.custom_model_name || 'Unknown',
            chassis_type: c.car_model&.chassis_type,
            driveline: c.effective_driveline,
            year_released: c.year_released,
            transponder_number: c.transponder_number
          }
        }
      }
    end


    def models
      manufacturer = DesManufacturer.find(params[:manufacturer_id])
      models = DesCarModel.where(manufacturer_id: manufacturer.id, status: ['approved', 'pending']).order(:name)
      render json: {
        models: models.map { |m| { id: m.id, name: m.name, year_released: m.year_released, driveline: m.driveline, chassis_type: m.chassis_type, status: m.status } }
      }
    end

    def create
      car_attributes = build_car_attributes
      car = DesUserCar.new(car_attributes)
      if car.save
        render json: serialize_car(car.reload), status: :created
      else
        render json: { errors: car.errors.full_messages }, status: :unprocessable_entity
      end
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def update
      car = DesUserCar.find_by(id: params[:id], user_id: current_user.id)
      raise Discourse::InvalidAccess unless car
      if car.update(permitted_car_params)
        render json: serialize_car(car.reload)
      else
        render json: { errors: car.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      car = DesUserCar.find_by(id: params[:id], user_id: current_user.id)
      raise Discourse::InvalidAccess unless car
      car.update!(status: 'inactive')
      render json: { success: true }
    end

    def suggest_manufacturer
      manufacturer = DesManufacturer.find_or_initialize_by(name: params[:name])
      if manufacturer.new_record?
        manufacturer.status = 'pending'
        manufacturer.created_by = current_user.id
        manufacturer.save!
        render json: { id: manufacturer.id, name: manufacturer.name, status: manufacturer.status }, status: :created
      else
        render json: { id: manufacturer.id, name: manufacturer.name, status: manufacturer.status }
      end
    end

    def suggest_model
      normalised_name = params[:name].to_s.strip.squeeze(" ").split.map(&:capitalize).join(" ")
      existing = DesCarModel.where(manufacturer_id: params[:manufacturer_id])
        .where("LOWER(name) = ?", normalised_name.downcase).first
      if existing
        render json: { id: existing.id, name: existing.name, status: existing.status }
        return
      end
      model = DesCarModel.create!(
        manufacturer_id: params[:manufacturer_id],
        name: normalised_name,
        year_released: params[:year_released].present? ? params[:year_released].to_i : nil,
        driveline: params[:driveline].present? ? params[:driveline] : nil,
        chassis_type: params[:chassis_type].present? ? params[:chassis_type] : nil,
        status: 'pending',
        created_by: current_user.id
      )
      render json: { id: model.id, name: model.name, status: model.status }, status: :created
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    private

    def build_car_attributes
      cp = params[:car]
      attrs = {
        manufacturer_id: cp[:manufacturer_id],
        car_model_id: cp[:car_model_id],
        class_type_id: cp[:class_type_id],
        driveline: cp[:driveline],
        transponder_number: cp[:transponder_number],
        friendly_name: cp[:friendly_name],
        custom_model_name: cp[:custom_model_name],
        user_id: current_user.id
      }

      # If custom model name given, check if it matches an existing model
      if attrs[:custom_model_name].present? && attrs[:manufacturer_id].present?
        normalised = attrs[:custom_model_name].strip.squeeze(" ").split.map(&:capitalize).join(" ")
        existing = DesCarModel.where(manufacturer_id: attrs[:manufacturer_id])
          .where("LOWER(name) = ?", normalised.downcase).first
        if existing
          attrs[:car_model_id] = existing.id
          attrs[:custom_model_name] = nil
        end
      end

      attrs
    end

    def permitted_car_params
      params.require(:car).permit(
        :manufacturer_id, :car_model_id, :class_type_id,
        :driveline, :transponder_number, :friendly_name, :custom_model_name
      )
    end

    def serialize_car(car)
      {
        id: car.id,
        friendly_name: car.display_name,
        manufacturer: car.manufacturer ? { id: car.manufacturer_id, name: car.manufacturer.name } : { id: nil, name: 'Unknown' },
        model: car.car_model ? {
          id: car.car_model_id,
          name: car.car_model.name,
          year_released: car.car_model.year_released,
          driveline: car.car_model.driveline,
          chassis_type: car.car_model.chassis_type,
          status: car.car_model.status
        } : nil,
        custom_model_name: car.custom_model_name,
        class_type: car.class_type ? { id: car.class_type_id, name: car.class_type.name } : nil,
        driveline: car.effective_driveline,
        year_released: car.year_released,
        transponder_number: car.transponder_number,
        model_approved: car.model_approved?,
        status: car.status
      }
    end

    def serialize_cars(cars)
      cars.map { |c| serialize_car(c) }
    end
  end
end
