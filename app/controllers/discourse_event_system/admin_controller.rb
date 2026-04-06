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
        class_types: DesEventClassType.all.map { |ct| { id: ct.id, name: ct.name } },
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
        year_released: params[:year_released].present? ? params[:year_released].to_i : model.year_released,
        driveline: params[:driveline].present? ? params[:driveline] : model.driveline,
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

    def approve_model
      model = DesCarModel.find(params[:id])
      model.update!(
        status: 'approved',
        year_released: params[:year_released].present? ? params[:year_released].to_i : nil,
        driveline: params[:driveline].present? ? params[:driveline] : nil
      )
      render json: { success: true }
    end

    def reject_model
      model = DesCarModel.find(params[:id])
      model.update!(status: 'rejected')
      render json: { success: true }
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
        year_released: model.year_released,
        driveline: model.driveline,
        chassis_type: model.chassis_type,
        created_by: model.creator&.username,
        status: model.status
      }
    end
  end
end
