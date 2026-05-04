# frozen_string_literal: true

module DiscourseEventSystem
  class VenuesController < ApplicationController
    before_action :ensure_logged_in, except: [:index, :show]

    def index
      venues = DesVenue.includes(:tracks).approved.order(:name)
      render json: { venues: venues.map { |v| serialize_venue(v) } }
    end

    def show
      venue = DesVenue.includes(:tracks).find(params[:id])
      native_events = DesEvent.where(venue_id: venue.id, status: 'published')
        .where('start_date > ?', Time.now)
        .order(:start_date).limit(10)
        .map { |e|
          { id: e.id, title: e.title, start_date: e.start_date, formatted_date: e.start_date&.strftime('%a %d %b %Y at %H:%M'), organisation_name: e.organisation&.name, type: 'native', topic_url: e.topic_id ? "/t/#{e.topic_id}" : nil }
        }

      imported_events = DesImportedEvent.where(venue_id: venue.id)
        .where('starts_at > ?', Time.now)
        .order(:starts_at).limit(10)
        .map { |e|
          { id: e.id, title: e.title, start_date: e.starts_at, formatted_date: e.starts_at&.strftime('%a %d %b %Y at %H:%M'), organisation_name: e.organisation&.name, type: 'imported', booking_url: e.booking_url }
        }

      upcoming_events = (native_events + imported_events)
        .sort_by { |e| e[:start_date] }
        .first(10)

      render json: {
        venue: serialize_venue(venue).merge(can_edit: current_user.present? && (current_user.admin? || (venue.created_by_organisation_id.present? && is_org_admin?(venue.created_by_organisation_id)))),
        upcoming_events: upcoming_events
      }
    end

    def create
      venue = DesVenue.new(venue_params)
      venue.status = current_user.admin? ? 'approved' : 'pending'
      if venue.save
        render json: { venue: serialize_venue(venue) }, status: :created
      else
        render json: { errors: venue.errors.full_messages }, status: :unprocessable_entity
      end
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def update
      venue = DesVenue.find(params[:id])
      unless current_user.admin? || venue.created_by_organisation_id.present? && is_org_admin?(venue.created_by_organisation_id)
        raise Discourse::InvalidAccess
      end
      if venue.update(venue_params)
        render json: { venue: serialize_venue(venue) }
      else
        render json: { errors: venue.errors.full_messages }, status: :unprocessable_entity
      end
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def destroy
      raise Discourse::InvalidAccess unless current_user.admin?
      venue = DesVenue.find(params[:id])
      venue.destroy!
      render json: { success: true }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def admin_index
      raise Discourse::InvalidAccess unless current_user.admin?
      venues = DesVenue.order(:name).includes(:organisation, :tracks)
      render json: { venues: venues.map { |v| serialize_venue(v) } }
    end

    def geocode_all
      raise Discourse::InvalidAccess unless current_user.admin?
      venues = DesVenue.where.not(postcode: [nil, '']).where(latitude: nil)
      venues.each do |venue|
        ::Jobs.enqueue(:discourse_event_system_geocode_venue, venue_id: venue.id)
      end
      render json: { queued: venues.count }
    end

    def claim_venue
      raise Discourse::NotLoggedIn unless current_user
      venue = DesVenue.find(params[:id])

      organisation_id = params[:organisation_id].to_i
      raise Discourse::InvalidAccess unless is_org_admin?(organisation_id)

      if venue.claim_status == 'approved'
        return render json: { error: 'This venue has already been claimed' }, status: :unprocessable_entity
      end

      venue.update!(
        claimed_organisation_id: organisation_id,
        claim_status: 'pending'
      )
      render json: { success: true }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def create_suggestion
      raise Discourse::NotLoggedIn unless current_user
      venue = DesVenue.find(params[:venue_id])

      suggestion = DesVenueSuggestion.create!(
        venue_id: venue.id,
        user_id: current_user.id,
        suggested_data: params[:suggested_data].permit!.to_h,
        status: 'pending'
      )
      render json: { success: true, suggestion_id: suggestion.id }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def admin_approve
      raise Discourse::InvalidAccess unless current_user.admin?
      venue = DesVenue.find(params[:id])
      venue.approve!
      render json: { success: true }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    private

    def venue_params
      params.permit(
        :name, :address, :google_maps_url, :website, :description, :parking_info,
        :local_facilities, :access_notes, :created_by_organisation_id,
        :has_portaloos, :has_permanent_toilets, :has_bar, :has_cafe, :has_showers,
        :has_power_supply, :has_water_supply, :has_camping, :has_track_shop, :is_shared, :postcode
      )
    end

    def serialize_venue(venue)
      {
        id: venue.id,
        name: venue.name,
        address: venue.address,
        google_maps_url: venue.google_maps_url,
        website: venue.website,
        description: venue.description,
        parking_info: venue.parking_info,
        local_facilities: venue.local_facilities,
        access_notes: venue.access_notes,
        status: venue.status,
        created_by_organisation_id: venue.created_by_organisation_id,
        organisation_name: venue.organisation&.name,
        has_portaloos: venue.has_portaloos,
        has_permanent_toilets: venue.has_permanent_toilets,
        has_bar: venue.has_bar,
        has_cafe: venue.has_cafe,
        has_showers: venue.has_showers,
        has_power_supply: venue.has_power_supply,
        has_water_supply: venue.has_water_supply,
        has_camping: venue.has_camping,
        has_track_shop: venue.has_track_shop,
        is_shared: venue.is_shared,
        is_stub: venue.is_stub,
        claim_status: venue.claim_status,
        claimed_organisation_id: venue.claimed_organisation_id,
        claimed_organisation_name: venue.claimed_organisation&.name,
        postcode: venue.postcode,
        latitude: venue.latitude,
        longitude: venue.longitude,
        tracks: venue.tracks.map { |t|
          { id: t.id, name: t.name, surface: t.surface, environment: t.environment, description: t.description }
        }
      }
    end

    def is_org_admin?(org_id)
      DesOrganisationMember.joins(:position)
        .where(organisation_id: org_id, user_id: current_user.id, status: 'active')
        .where(des_positions: { is_admin: true }).exists? || current_user.admin?
    end
  end
end
