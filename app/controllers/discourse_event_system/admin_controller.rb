# frozen_string_literal: true

module DiscourseEventSystem
  class AdminController < ApplicationController
    before_action :ensure_logged_in
    before_action :ensure_admin, except: [:scales, :chassis_types]

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
        global_class_types: DesEventClassType.global.map { |ct| serialize_class_type(ct) },
        org_class_type_groups: DesEventClassType.where.not(organisation_id: nil).includes(:organisation).group_by(&:organisation_id).map { |org_id, cts|
          org = cts.first.organisation
          { organisation_id: org_id, organisation_name: org&.name || "Unknown", class_types: cts.map { |ct| serialize_class_type(ct) } }
        }.sort_by { |g| g[:organisation_name] },
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
        chassis_type: params[:chassis_type].present? ? params[:chassis_type] : model.chassis_type,
        power_type: params.key?(:power_type) ? (params[:power_type].presence || model.power_type) : model.power_type
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
      attrs = { name: params[:name].to_s.strip }
      attrs[:logo_upload_id] = params[:logo_upload_id].presence if params.key?(:logo_upload_id)
      manufacturer.update!(attrs)
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
        power_type: params[:power_type].presence || 'electric',
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
        power_type: params[:power_type].presence,
        chassis_types: params[:chassis_types].present? ? Array(params[:chassis_types]).join(',') : nil,
        drivelines: params[:drivelines].present? ? Array(params[:drivelines]).join(',') : nil,
        min_year: params[:min_year].presence,
        max_year: params[:max_year].presence,
        manufacturer: params[:manufacturer].presence,
        model_id: params[:model_id].presence,
        min_age: params[:min_age].presence,
        max_age: params[:max_age].presence
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
        power_type: params.key?(:power_type) ? params[:power_type].presence : ct.power_type,
        chassis_types: params.key?(:chassis_types) ? (params[:chassis_types].present? ? Array(params[:chassis_types]).join(',') : nil) : ct.chassis_types,
        drivelines: params.key?(:drivelines) ? (params[:drivelines].present? ? Array(params[:drivelines]).join(',') : nil) : ct.drivelines,
        min_year: params.key?(:min_year) ? params[:min_year].presence : ct.min_year,
        max_year: params.key?(:max_year) ? params[:max_year].presence : ct.max_year,
        manufacturer: params.key?(:manufacturer) ? params[:manufacturer].presence : ct.manufacturer,
        model_id: params.key?(:model_id) ? params[:model_id].presence : ct.model_id,
        min_age: params.key?(:min_age) ? params[:min_age].presence : ct.min_age,
        max_age: params.key?(:max_age) ? params[:max_age].presence : ct.max_age
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

    # Tracks
    def create_track
      venue = DesVenue.find(params[:venue_id])
      track = venue.tracks.create!(
        name: params[:name].presence,
        surface: params[:surface].presence,
        environment: params[:environment].presence,
        description: params[:description].presence,
        sort_order: params[:sort_order].to_i
      )
      render json: { track: serialize_track(track) }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def update_track
      track = DesVenueTrack.find(params[:id])
      track.update!(
        name: params[:name].presence || track.name,
        surface: params[:surface].presence || track.surface,
        environment: params[:environment].presence || track.environment,
        description: params[:description].presence,
        sort_order: params[:sort_order].present? ? params[:sort_order].to_i : track.sort_order
      )
      render json: { track: serialize_track(track) }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def destroy_track
      track = DesVenueTrack.find(params[:id])
      track.destroy
      render json: { success: true }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def approve_venue_claim
      venue = DesVenue.find(params[:id])
      venue.update!(claim_status: 'approved', is_stub: false)
      render json: { success: true }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def reject_venue_claim
      venue = DesVenue.find(params[:id])
      venue.update!(claim_status: 'unclaimed', claimed_organisation_id: nil)
      render json: { success: true }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def merge_venues
      keep_id = params[:keep_id].to_i
      merge_id = params[:merge_id].to_i

      return render json: { error: 'Cannot merge a venue with itself' }, status: :unprocessable_entity if keep_id == merge_id

      keeper = DesVenue.find(keep_id)
      to_merge = DesVenue.find(merge_id)

      DesEvent.where(venue_id: merge_id).update_all(venue_id: keep_id)
      DesImportedEvent.where(venue_id: merge_id).update_all(venue_id: keep_id)

      if keeper.tracks.empty?
        to_merge.tracks.update_all(venue_id: keep_id)
      end

      DesVenueSuggestion.where(venue_id: merge_id).update_all(venue_id: keep_id)

      if to_merge.claim_status == 'approved' && keeper.claim_status != 'approved'
        keeper.update!(
          claimed_organisation_id: to_merge.claimed_organisation_id,
          claim_status: 'approved'
        )
      end

      to_merge.destroy

      render json: { success: true }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def venue_suggestions
      suggestions = DesVenueSuggestion.includes(:venue, :user).order(created_at: :desc)
      render json: {
        pending: suggestions.where(status: 'pending').map { |s| serialize_suggestion(s) },
        resolved: suggestions.where(status: %w[approved rejected]).limit(20).map { |s| serialize_suggestion(s) }
      }
    end

    def approve_venue_suggestion
      suggestion = DesVenueSuggestion.find(params[:id])
      venue = suggestion.venue

      data = suggestion.suggested_data.symbolize_keys
      tracks_data = data.delete(:tracks)

      allowed_fields = %w[name description parking_info website has_portaloos
        has_permanent_toilets has_bar has_cafe has_showers has_power_supply
        has_water_supply has_camping has_track_shop]
      venue_updates = data.stringify_keys.slice(*allowed_fields)
      venue.update!(venue_updates) if venue_updates.any?

      if tracks_data.present?
        tracks_data.each do |track|
          track = track.symbolize_keys
          if track[:id].present?
            existing = DesVenueTrack.find_by(id: track[:id], venue_id: venue.id)
            existing&.update!(track.slice(:name, :surface, :environment, :description))
          else
            venue.tracks.create!(track.slice(:name, :surface, :environment, :description))
          end
        end
      end

      venue.update!(is_stub: false) if venue.is_stub?
      suggestion.update!(status: 'approved')
      render json: { success: true }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def reject_venue_suggestion
      suggestion = DesVenueSuggestion.find(params[:id])
      suggestion.update!(status: 'rejected', admin_notes: params[:admin_notes])
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
        power_type: ct.power_type,
        chassis_types: ct.chassis_types_list,
        drivelines: ct.drivelines_list,
        min_year: ct.min_year,
        max_year: ct.max_year,
        manufacturer: ct.manufacturer,
        model_id: ct.model_id,
        min_age: ct.min_age,
        max_age: ct.max_age
      }
    end

    def serialize_manufacturer(manufacturer)
      {
        id: manufacturer.id,
        name: manufacturer.name,
        created_by: manufacturer.creator&.username,
        status: manufacturer.status,
        logo_upload_id: manufacturer.logo_upload_id,
        logo_url: manufacturer.logo&.url
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

    def serialize_suggestion(s)
      {
        id: s.id,
        venue_id: s.venue_id,
        venue_name: s.venue&.name,
        user: s.user&.username,
        suggested_data: s.suggested_data,
        status: s.status,
        admin_notes: s.admin_notes,
        created_at: s.created_at&.strftime('%d %b %Y')
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
        power_type: model.power_type,
        created_by: model.creator&.username,
        status: model.status
      }
    end

    def serialize_track(track)
      { id: track.id, venue_id: track.venue_id, name: track.name, surface: track.surface, environment: track.environment, description: track.description, sort_order: track.sort_order }
    end
  end
end
