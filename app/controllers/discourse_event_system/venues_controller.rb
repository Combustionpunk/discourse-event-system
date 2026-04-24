# frozen_string_literal: true

module DiscourseEventSystem
  class VenuesController < ApplicationController
    before_action :ensure_logged_in, except: [:index, :show]

    def index
      venues = DesVenue.approved.order(:name)
      render json: { venues: venues.map { |v| serialize_venue(v) } }
    end

    def show
      venue = DesVenue.find(params[:id])
      upcoming_events = DesEvent.where(venue_id: venue.id, status: 'published')
        .where('start_date > ?', Time.now)
        .order(:start_date).limit(10)
      render json: {
        venue: serialize_venue(venue).merge(can_edit: current_user.present? && (current_user.admin? || (venue.created_by_organisation_id.present? && is_org_admin?(venue.created_by_organisation_id)))),
        upcoming_events: upcoming_events.map { |e|
          { id: e.id, title: e.title, start_date: e.start_date, organisation_name: e.organisation&.name }
        }
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
      venues = DesVenue.order(:name).includes(:organisation)
      render json: { venues: venues.map { |v| serialize_venue(v) } }
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
        :name, :address, :google_maps_url, :track_category, :track_surface,
        :track_environment, :website, :description, :parking_info,
        :local_facilities, :access_notes, :created_by_organisation_id,
        :has_portaloos, :has_permanent_toilets, :has_bar, :has_showers,
        :has_power_supply, :has_water_supply, :has_camping, :is_shared
      )
    end

    def serialize_venue(venue)
      {
        id: venue.id,
        name: venue.name,
        address: venue.address,
        google_maps_url: venue.google_maps_url,
        track_category: venue.track_category,
        track_surface: venue.track_surface,
        track_environment: venue.track_environment,
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
        has_showers: venue.has_showers,
        has_power_supply: venue.has_power_supply,
        has_water_supply: venue.has_water_supply,
        has_camping: venue.has_camping,
        is_shared: venue.is_shared
      }
    end

    def is_org_admin?(org_id)
      DesOrganisationMember.joins(:position)
        .where(organisation_id: org_id, user_id: current_user.id, status: 'active')
        .where(des_positions: { is_admin: true }).exists? || current_user.admin?
    end
  end
end
