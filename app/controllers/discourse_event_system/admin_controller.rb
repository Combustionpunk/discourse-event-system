# frozen_string_literal: true

module DiscourseEventSystem
  class AdminController < ApplicationController
    before_action :ensure_logged_in
    before_action :ensure_admin

    def index
      render json: {
        pending_organisations: DesOrganisation.pending.map { |o| serialize_organisation(o) },
        approved_organisations: DesOrganisation.approved.map { |o| serialize_organisation(o) },
        rejected_organisations: DesOrganisation.rejected.map { |o| serialize_organisation(o) },
        pending_manufacturers: DesManufacturer.pending.map { |m| serialize_manufacturer(m) },
        approved_manufacturers: DesManufacturer.approved.order(:name).map { |m| serialize_manufacturer(m) },
        pending_models: DesCarModel.pending.includes(:manufacturer).map { |m| serialize_model(m) },
        approved_models: DesCarModel.approved.includes(:manufacturer).map { |m| serialize_model(m) },
        approved_models_by_manufacturer: DesCarModel.approved.includes(:manufacturer).order("des_manufacturers.name, des_car_models.name").group_by { |m| m.manufacturer&.name || "Unknown" }.map { |mfr, models| { manufacturer: mfr, models: models.map { |m| serialize_model(m) } } },
        class_types: DesEventClassType.all.map { |ct| serialize_class_type(ct) },
        global_rules: DesClassCompatibilityRule.global.includes(:class_type).map { |r| serialize_rule(r) }
      }
    end

    def create_rule
      rule = DesClassCompatibilityRule.create!(
        class_type_id: params[:class_type_id],
        rule_type: params[:rule_type],
        rule_value: params[:rule_value],
        organisation_id: nil
      )
      render json: serialize_rule(rule), status: :created
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def destroy_rule
      rule = DesClassCompatibilityRule.find(params[:id])
      rule.destroy
      render json: { success: true }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def update_model
      model = DesCarModel.find(params[:id])
      model.update!(
        manufacturer_id: params[:manufacturer_id].present? ? params[:manufacturer_id].to_i : model.manufacturer_id,
        name: params[:name].present? ? params[:name].strip : model.name,
        year_released: params[:year_released].present? ? params[:year_released].to_i : model.year_released,
        driveline: params[:driveline].present? ? params[:driveline] : model.driveline,
        scale: params[:scale].present? ? params[:scale] : model.scale,
        chassis_type: params[:chassis_type].present? ? params[:chassis_type] : model.chassis_type
      )
      render json: serialize_model(model)
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def approve_organisation
      org = DesOrganisation.find(params[:id])
      org.approve!(params[:surcharge_percentage].to_f)
      render json: { success: true }
    end

    def reject_organisation
      org = DesOrganisation.find(params[:id])
      org.reject!(params[:reason])
      render json: { success: true }
    end

    def approve_manufacturer
      manufacturer = DesManufacturer.find(params[:id])
      manufacturer.approve!
      render json: { success: true }
    end

    def reject_manufacturer
      manufacturer = DesManufacturer.find(params[:id])
      manufacturer.reject!
      render json: { success: true }
    end

    def update_manufacturer
      manufacturer = DesManufacturer.find(params[:id])
      manufacturer.update!(name: params[:name].to_s.strip)
      render json: { success: true, name: manufacturer.name }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def destroy_manufacturer
      manufacturer = DesManufacturer.find(params[:id])
      linked_models = DesCarModel.where(manufacturer_id: manufacturer.id, status: 'approved').count
      if linked_models > 0
        return render json: { error: "Cannot delete: #{linked_models} approved car model(s) are linked to this manufacturer. Delete or reassign them first." }, status: :unprocessable_entity
      end
      DesCarModel.where(manufacturer_id: manufacturer.id).destroy_all
      manufacturer.destroy!
      render json: { success: true }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end


    def create_model
      manufacturer = DesManufacturer.find(params[:manufacturer_id])
      model = DesCarModel.create!(
        manufacturer_id: params[:manufacturer_id],
        name: params[:name].to_s.strip,
        year_released: params[:year_released].present? ? params[:year_released].to_i : nil,
        driveline: params[:driveline].presence,
        scale: params[:scale].presence,
        chassis_type: params[:chassis_type].presence,
        status: 'approved',
        created_by: current_user.id
      )
      render json: serialize_model(model), status: :created
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def approve_model
      model = DesCarModel.find(params[:id])
      model.update!(
        status: 'approved',
        year_released: params[:year_released].present? ? params[:year_released].to_i : nil,
        driveline: params[:driveline].present? ? params[:driveline] : nil,
        scale: params[:scale].present? ? params[:scale] : nil,
        chassis_type: params[:chassis_type].present? ? params[:chassis_type] : nil
      )
      render json: { success: true }
    end

    def reject_model
      model = DesCarModel.find(params[:id])
      model.update!(status: 'rejected')
      render json: { success: true }
    end

    def destroy_model
      model = DesCarModel.find(params[:id])
      DesUserCar.where(car_model_id: model.id).update_all(car_model_id: nil)
      model.destroy!
      render json: { success: true }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def orphaned_cars
      cars = DesUserCar.active
        .includes(:user, :manufacturer, :car_model)
        .where("manufacturer_id IS NULL OR car_model_id IS NULL OR car_model_id IN (?)",
          DesCarModel.where(status: 'rejected').pluck(:id).presence || [0])
      render json: {
        cars: cars.map { |c|
          {
            id: c.id,
            username: c.user&.username,
            friendly_name: c.display_name,
            manufacturer_id: c.manufacturer_id,
            manufacturer_name: c.manufacturer&.name,
            car_model_id: c.car_model_id,
            model_name: c.car_model&.name,
            model_status: c.car_model&.status,
            transponder_number: c.transponder_number
          }
        }
      }
    end

    def update_car
      car = DesUserCar.find(params[:id])
      car.update!(
        manufacturer_id: params[:manufacturer_id].present? ? params[:manufacturer_id].to_i : car.manufacturer_id,
        car_model_id: params[:car_model_id].present? ? params[:car_model_id].to_i : car.car_model_id
      )
      render json: { success: true }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def destroy_car
      car = DesUserCar.find(params[:id])
      car.update!(status: 'inactive')
      render json: { success: true }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def scales
      render json: { scales: DesScale.order(:position, :name).map { |s| { id: s.id, name: s.name } } }
    end

    def create_scale
      scale = DesScale.create!(name: params[:name].to_s.strip)
      render json: { id: scale.id, name: scale.name }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def destroy_scale
      DesScale.find(params[:id]).destroy!
      render json: { success: true }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def chassis_types
      render json: { chassis_types: DesChassisType.order(:position, :name).map { |c| { id: c.id, name: c.name } } }
    end

    def create_chassis_type
      ct = DesChassisType.create!(name: params[:name].to_s.strip)
      render json: { id: ct.id, name: ct.name }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def destroy_chassis_type
      DesChassisType.find(params[:id]).destroy!
      render json: { success: true }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def create_class_type
      ct = DesEventClassType.create!(
        name: params[:name].to_s.strip,
        track_environment: params[:track_environment].presence,
        scale: params[:scale].presence,
        chassis_types: params[:chassis_types].present? ? Array(params[:chassis_types]).join(',') : nil,
        drivelines: params[:drivelines].present? ? Array(params[:drivelines]).join(',') : nil
      )
      render json: serialize_class_type(ct), status: :created
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def update_class_type
      ct = DesEventClassType.find(params[:id])
      ct.update!(
        name: params[:name].present? ? params[:name].to_s.strip : ct.name,
        track_environment: params.key?(:track_environment) ? params[:track_environment].presence : ct.track_environment,
        scale: params.key?(:scale) ? params[:scale].presence : ct.scale,
        chassis_types: params.key?(:chassis_types) ? (params[:chassis_types].present? ? Array(params[:chassis_types]).join(',') : nil) : ct.chassis_types,
        drivelines: params.key?(:drivelines) ? (params[:drivelines].present? ? Array(params[:drivelines]).join(',') : nil) : ct.drivelines
      )
      render json: serialize_class_type(ct)
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def destroy_class_type
      ct = DesEventClassType.find(params[:id])
      ct.destroy!
      render json: { success: true }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    private

    def ensure_admin
      raise Discourse::InvalidAccess unless current_user.admin?
    end

    def serialize_organisation(org)
      {
        id: org.id,
        name: org.name,
        description: org.description,
        email: org.email,
        website: org.website,
        address: org.address,
        paypal_email: org.paypal_email,
        surcharge_percentage: org.surcharge_percentage,
        rejection_reason: org.rejection_reason,
        created_by: org.creator&.username,
        status: org.status
      }
    end

    def serialize_class_type(ct)
      {
        id: ct.id,
        name: ct.name,
        track_environment: ct.track_environment,
        scale: ct.scale,
        chassis_types: ct.chassis_types_list,
        drivelines: ct.drivelines_list
      }
    end

    def serialize_manufacturer(manufacturer)
      {
        id: manufacturer.id,
        name: manufacturer.name,
        created_by: manufacturer.creator&.username,
        status: manufacturer.status
      }
    end

    def serialize_rule(rule)
      {
        id: rule.id,
        class_type_id: rule.class_type_id,
        class_type_name: rule.class_type&.name,
        rule_type: rule.rule_type,
        rule_value: rule.rule_value,
        organisation_id: rule.organisation_id
      }
    end

    def serialize_model(model)
      {
        id: model.id,
        name: model.name,
        manufacturer: model.manufacturer&.name || 'Unknown',
        manufacturer_id: model.manufacturer_id,
        year_released: model.year_released,
        driveline: model.driveline,
        scale: model.scale,
        chassis_type: model.chassis_type,
        created_by: model.creator&.username,
        status: model.status
      }
    end
  end
end
