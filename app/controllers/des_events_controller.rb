# frozen_string_literal: true

class DesEventsController < ApplicationController
  before_action :ensure_logged_in, except: [:index, :show]
  before_action :set_event, only: [:show, :update, :destroy, :publish, :cancel]

  def index
    events = DesEvent.published.upcoming.includes(:organisation, :event_type, :des_event_classes)
    render json: serialize_events(events)
  end

  def show
    render json: serialize_event(@event)
  end

  def create
    organisation = DesOrganisation.find(params[:organisation_id])
    ensure_organisation_admin!(organisation)

    event = DesEvent.new(event_params)
    event.created_by = current_user.id

    if event.save
      render json: serialize_event(event), status: :created
    else
      render json: { errors: event.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    ensure_organisation_admin!(@event.organisation)

    if @event.update(event_params)
      @event.update_topic_content! if @event.topic_id.present?
      render json: serialize_event(@event)
    else
      render json: { errors: @event.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def publish
    ensure_organisation_admin!(@event.organisation)
    @event.publish!
    render json: serialize_event(@event)
  end

  def cancel
    ensure_organisation_admin!(@event.organisation)
    service = DesBookingService.new(current_user, @event)
    result = service.cancel_event_and_refund(params[:reason], current_user)
    render json: { event: serialize_event(@event), refund_summary: result.summary }
  end

  private

  def set_event
    @event = DesEvent.find(params[:id])
  end

  def event_params
    params.require(:event).permit(
      :title, :description, :organisation_id, :event_type_id,
      :start_date, :end_date, :location, :google_maps_url,
      :capacity, :refund_cutoff_days, :category_id
    )
  end

  def ensure_organisation_admin!(organisation)
    member = DesOrganisationMember
      .joins(:position)
      .where(organisation_id: organisation.id, user_id: current_user.id, status: 'active')
      .where(des_positions: { is_admin: true })
      .exists?

    raise Discourse::InvalidAccess unless member || current_user.admin?
  end

  def serialize_event(event)
    {
      id: event.id,
      title: event.title,
      description: event.description,
      organisation: {
        id: event.organisation.id,
        name: event.organisation.name
      },
      event_type: {
        id: event.event_type.id,
        name: event.event_type.name
      },
      start_date: event.start_date,
      end_date: event.end_date,
      location: event.location,
      google_maps_url: event.google_maps_url,
      capacity: event.capacity,
      status: event.status,
      topic_url: event.topic&.url,
      classes: event.des_event_classes.map do |ec|
        {
          id: ec.id,
          name: ec.name,
          capacity: ec.capacity,
          status: ec.status,
          spaces_remaining: ec.spaces_remaining
        }
      end,
      pricing: event.des_event_pricing_rule ? {
        rule_type: event.des_event_pricing_rule.rule_type,
        flat_price: event.des_event_pricing_rule.flat_price,
        first_class_price: event.des_event_pricing_rule.first_class_price,
        subsequent_class_price: event.des_event_pricing_rule.subsequent_class_price
      } : nil
    }
  end

  def serialize_events(events)
    events.map { |e| serialize_event(e) }
  end
end
