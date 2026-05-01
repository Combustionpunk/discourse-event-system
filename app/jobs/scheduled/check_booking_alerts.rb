# frozen_string_literal: true

module Jobs
  class CheckBookingAlerts < ::Jobs::Scheduled
    every 1.hour

    def execute(args)
      alerts = DesEventBookingAlert
        .includes(:user, des_event: [:venue, :organisation])
        .joins(:des_event)
        .where(des_events: { status: 'published' })

      alerts.each do |alert|
        event = alert.des_event
        next unless event.booking_open?
        next unless alert.user&.email.present?

        begin
          DiscourseEventSystem::BookingAlertMailer.booking_open(alert.user, event).deliver_now

          notification_type = Notification.types[:custom] rescue Notification.types[:posted]
          Notification.create!(
            notification_type: notification_type,
            user_id: alert.user_id,
            high_priority: true,
            data: {
              message: "booking_alert",
              display_username: "system",
              topic_title: event.title,
              url: event.topic_id ? "/t/#{event.topic_id}" : "/events"
            }.to_json
          )

          alert.destroy!
        rescue => e
          Rails.logger.error("BookingAlert error for user #{alert.user_id}, event #{alert.event_id}: #{e.message}")
        end
      end
    end
  end
end
