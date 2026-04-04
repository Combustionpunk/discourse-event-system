# frozen_string_literal: true

module DiscourseEventSystem
  class EventsController < ApplicationController
    before_action :ensure_logged_in, except: [:index, :show]
    before_action :set_event, only: [:show, :update, :publish, :cancel, :entrants]

    def index
      events = DesEvent.published.upcoming.includes(:organisation, :event_type, :des_event_classes)
      render json: serialize_events(events)
    end

    def class_types
      render json: {
        class_types: DesEventClassType.all.order(:name).map { |ct| { id: ct.id, name: ct.name } }
      }
    end

    def event_types
      render json: {
        event_types: DesEventType.all.order(:name).map { |et| { id: et.id, name: et.name } }
      }
    end

    def event_types
      render json: {
        event_types: DesEventType.all.order(:name).map { |et| { id: et.id, name: et.name } }
      }
    end

    def show
      render json: serialize_event(@event)
    end

    def create
      organisation = DesOrganisation.find(params[:organisation_id])
      ensure_organisation_admin!(organisation)

      ActiveRecord::Base.transaction do
        event = DesEvent.new(event_params)
        event.created_by = current_user.id
        event.status = 'draft'
        event.save!

        # Create classes
        classes_array = params[:classes].present? ? params[:classes].values : []
        classes_array.each do |cls|
          class_type = DesEventClassType.find(cls[:class_type_id])
          DesEventClass.create!(
            event_id: event.id,
            class_type_id: cls[:class_type_id],
            name: class_type.name,
            capacity: cls[:capacity].to_i,
            status: 'active'
          )
        end

        # Create pricing rule
        if params[:pricing].present?
          DesEventPricingRule.create!(
            event_id: event.id,
            rule_type: params[:pricing][:rule_type],
            flat_price: params[:pricing][:flat_price],
            first_class_price: params[:pricing][:first_class_price],
            subsequent_class_price: params[:pricing][:subsequent_class_price]
          )
        end

        render json: serialize_event(event.reload), status: :created
      end
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
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

    def entrants
      ensure_organisation_admin!(@event.organisation)
      bookings = DesEventBooking.where(event_id: @event.id)
        .includes(:user, booking_classes: :event_class)
        .where.not(status: 'cancelled')

      render json: {
        event: { id: @event.id, title: @event.title },
        classes: @event.des_event_classes.map do |ec|
          class_bookings = bookings.select { |b| 
            b.booking_classes.any? { |bc| bc.event_class_id == ec.id }
          }
          {
            id: ec.id,
            name: ec.name,
            capacity: ec.capacity,
            spaces_remaining: ec.spaces_remaining,
            entrants: class_bookings.map do |b|
              bc = b.booking_classes.find { |bc| bc.event_class_id == ec.id }
              {
                booking_id: b.id,
                username: b.user.username,
                transponder: bc&.transponder_number,
                status: b.status,
                brca_number: b.brca_membership_number
              }
            end
          }
        end
      }
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
        :title, :description, :organisation_id, :event_type_id,
        :start_date, :end_date, :location, :google_maps_url,
        :capacity, :refund_cutoff_days, :category_id, :booking_closing_date,
        :booking_type, :external_booking_url, :external_booking_details
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
        organisation: { id: event.organisation.id, name: event.organisation.name },
        start_date: event.start_date,
        end_date: event.end_date,
        booking_closing_date: event.booking_closing_date,
        location: event.location,
        google_maps_url: event.google_maps_url,
        capacity: event.capacity,
        status: event.status,
        topic_url: event.topic ? "/t/#{event.topic.slug}/#{event.topic.id}" : nil,
        classes: event.des_event_classes.includes(:class_type).map do |ec|
          {
            id: ec.id,
            name: ec.class_type&.name || ec.name,
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
end
