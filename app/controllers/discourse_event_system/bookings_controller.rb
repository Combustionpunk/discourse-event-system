# frozen_string_literal: true

module DiscourseEventSystem
  class BookingsController < ApplicationController
    before_action :ensure_logged_in
    before_action :set_booking, only: [:show, :confirm, :cancel, :refund, :add_classes]

    def index
      bookings = DesEventBooking.where(user_id: current_user.id).includes(:event, :booking_classes)
      render json: serialize_bookings(bookings)
    end

    def eligible_cars
      event = DesEvent.find(params[:event_id])
      class_ids = params[:class_ids].is_a?(Array) ? params[:class_ids] : params[:class_ids].values

      cars = DesUserCar.where(user_id: current_user.id)
        .includes(:manufacturer, :car_model, :class_type)
        .active

      result = class_ids.map do |class_id|
        event_class = DesEventClass.find(class_id)
        eligible = cars.select { |car| car.eligible_for_class?(event_class) }
        {
          class_id: class_id,
          class_name: event_class.name,
          eligible_cars: eligible.map { |car|
            {
              id: car.id,
              friendly_name: car.display_name,
              driveline: car.effective_driveline,
              transponder_number: car.transponder_number,
              model: car.car_model&.name || car.custom_model_name
            }
          }
        }
      end

      render json: { classes: result }
    end

    def show
      ensure_booking_owner!
      render json: serialize_booking(@booking)
    end

    def create
      event = DesEvent.find(params[:event_id])
      service = DesBookingService.new(current_user, event)
      result = service.create_booking(params[:class_ids], params[:car_selections])
      render json: {
        booking: serialize_booking(result[:booking]),
        approval_url: result[:approval_url]
      }, status: :created
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def confirm
      ensure_booking_owner!
      service = DesBookingService.new(current_user, @booking.event)
      service.confirm_booking(@booking, params[:paypal_order_id])
      render json: serialize_booking(@booking.reload)
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def cancel
      ensure_booking_owner!
      service = DesBookingService.new(current_user, @booking.event)
      service.cancel_booking(@booking)
      render json: serialize_booking(@booking.reload)
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def refund
      ensure_booking_owner!
      service = DesBookingService.new(current_user, @booking.event)
      service.refund_booking(@booking, current_user, params[:reason])
      render json: serialize_booking(@booking.reload)
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def join_waitlist
      event = DesEvent.find(params[:event_id])
      event_class = DesEventClass.find(params[:event_class_id])

      # Check if already on waitlist
      existing = DesEventWaitlist.find_by(
        event_class_id: event_class.id,
        user_id: current_user.id,
        status: 'waiting'
      )
      return render json: { error: 'Already on waitlist' }, status: :unprocessable_entity if existing

      # Check if class has spaces - if it does, no need to join waitlist
      if event_class.spaces_remaining > 0 && event_class.status != 'sold_out'
        return render json: { error: 'Class still has spaces available - please book directly' }, status: :unprocessable_entity
      end

      waitlist_entry = DesEventWaitlist.add_to_waitlist(event, event_class, current_user)
      render json: {
        id: waitlist_entry.id,
        position: waitlist_entry.position,
        class_name: event_class.name,
        status: waitlist_entry.status
      }, status: :created
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def leave_waitlist
      entry = DesEventWaitlist.find_by(id: params[:id], user_id: current_user.id)
      return render json: { error: 'Not found' }, status: :not_found unless entry
      entry.expire!
      render json: { success: true }
    end

    def my_waitlist
      entries = DesEventWaitlist.where(user_id: current_user.id)
        .where(status: ['waiting', 'notified'])
        .includes(:event, :event_class)
      render json: {
        waitlist: entries.map { |e|
          {
            id: e.id,
            event: { id: e.event.id, title: e.event.title, start_date: e.event.start_date },
            class_name: e.event_class.name,
            position: e.position,
            status: e.status
          }
        }
      }
    end

    def add_classes
      ensure_booking_owner!
      service = DesBookingService.new(current_user, @booking.event)
      result = service.add_classes(@booking, params[:class_ids])
      render json: {
        booking: serialize_booking(result[:booking].reload),
        approval_url: result[:approval_url]
      }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    private

    def set_booking
      @booking = DesEventBooking.find(params[:id])
    end

    def ensure_booking_owner!
      raise Discourse::InvalidAccess unless @booking.user_id == current_user.id || current_user.admin?
    end

    def serialize_booking(booking)
      {
        id: booking.id,
        event: {
          id: booking.event.id,
          title: booking.event.title,
          start_date: booking.event.start_date,
          location: booking.event.location,
          topic_url: booking.event.topic&.url
        },
        status: booking.status,
        total_amount: booking.total_amount,
        discount_amount: booking.discount_amount,
        amount_paid: booking.amount_paid,
        brca_membership_number: booking.brca_membership_number,
        classes: booking.booking_classes.map do |bc|
          {
            id: bc.id,
            class_name: bc.event_class.name,
            status: bc.status,
            amount_charged: bc.amount_charged,
            transponder_number: bc.transponder_number,
            transponder_overridden: bc.transponder_overridden
          }
        end,
        payments: booking.payments.map do |p|
          {
            id: p.id,
            amount: p.amount,
            status: p.status,
            payment_type: p.payment_type,
            created_at: p.created_at
          }
        end
      }
    end

    def serialize_bookings(bookings)
      bookings.map { |b| serialize_booking(b) }
    end
  end
end
