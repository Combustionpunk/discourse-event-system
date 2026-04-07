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

    def waitlist_promoted(waitlist_entry)
      @entry = waitlist_entry
      @user = waitlist_entry.user
      @event = waitlist_entry.event
      @event_class = waitlist_entry.event_class

      mail(
        to: @user.email,
        subject: "A space is available! - #{@event.title} - #{@event_class.name}"
      )
    end

    def membership_expiry_reminder(membership, days)
      @user = membership.user
      @organisation = membership.organisation
      @membership_type = membership.membership_type
      @days_left = days
      @expires_at = membership.expires_at

      mail(
        to: @user.email,
        subject: "Membership Expiring Soon - #{@organisation.name}"
      )
    end

    def membership_expired(membership)
      @user = membership.user
      @organisation = membership.organisation
      @membership_type = membership.membership_type

      mail(
        to: @user.email,
        subject: "Membership Expired - #{@organisation.name}"
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
