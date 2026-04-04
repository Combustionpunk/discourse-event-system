# frozen_string_literal: true

module DiscourseEventSystem
  class EventMailer < ActionMailer::Base
    default from: SiteSetting.notification_email

    def booking_confirmed(booking)
      @booking = booking
      @user = booking.user
      @event = booking.event
      @classes = booking.booking_classes.includes(:event_class)

      mail(
        to: @user.email,
        subject: "Booking Confirmed - #{@event.title}"
      )
    end

    def booking_cancelled(booking, reason = nil)
      @booking = booking
      @user = booking.user
      @event = booking.event
      @reason = reason

      mail(
        to: @user.email,
        subject: "Booking Cancelled - #{@event.title}"
      )
    end

    def event_cancelled(booking, reason)
      @booking = booking
      @user = booking.user
      @event = booking.event
      @reason = reason

      mail(
        to: @user.email,
        subject: "Event Cancelled - #{@event.title}"
      )
    end

    def event_updated(booking, changes)
      @booking = booking
      @user = booking.user
      @event = booking.event
      @changes = changes

      mail(
        to: @user.email,
        subject: "Event Updated - #{@event.title}"
      )
    end
  end
end
