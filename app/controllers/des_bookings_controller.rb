# frozen_string_literal: true

class DesBookingsController < ApplicationController
  before_action :ensure_logged_in
  before_action :set_booking, only: [:show, :confirm, :cancel, :refund, :add_classes]

  def index
    bookings = DesEventBooking.where(user_id: current_user.id).includes(:event, :booking_classes)
    render json: serialize_bookings(bookings)
  end

  def show
    ensure_booking_owner!
    render json: serialize_booking(@booking)
  end

  def create
    event = DesEvent.find(params[:event_id])
    service = DesBookingService.new(current_user, event)
    result = service.create_booking(params[:class_ids])
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
