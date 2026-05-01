# frozen_string_literal: true

module DiscourseEventSystem
  class BookingAlertMailer < ActionMailer::Base
    def booking_open(user, event)
      @user = user
      @event = event
      @event_url = "#{Discourse.base_url}#{event.topic_id ? "/t/#{event.topic_id}" : ''}"
      @event_date = event.start_date&.strftime('%A, %d %B %Y at %H:%M')
      @venue_name = event.venue&.name

      mail(
        to: user.email,
        from: SiteSetting.notification_email,
        subject: "🏁 Booking is now open — #{event.title}"
      ) do |format|
        format.html { render plain: booking_open_html }
        format.text { render plain: booking_open_text }
      end
    end

    private

    def booking_open_html
      <<~HTML
        <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #2ecc71;">🏁 Booking is now open!</h2>
          <p>Hi #{@user.username},</p>
          <p>You asked to be alerted when booking opened for <strong>#{@event.title}</strong>.</p>
          <table style="width:100%;border-collapse:collapse;margin:16px 0;">
            <tr><td style="padding:8px;font-weight:bold;">Event:</td><td style="padding:8px;">#{@event.title}</td></tr>
            #{@event_date ? "<tr><td style='padding:8px;font-weight:bold;'>Date:</td><td style='padding:8px;'>#{@event_date}</td></tr>" : ''}
            #{@venue_name ? "<tr><td style='padding:8px;font-weight:bold;'>Venue:</td><td style='padding:8px;'>#{@venue_name}</td></tr>" : ''}
          </table>
          <a href="#{@event_url}" style="display:inline-block;padding:12px 24px;background:#2ecc71;color:white;text-decoration:none;border-radius:6px;font-weight:bold;">View Event & Book Now</a>
          <p style="margin-top:24px;color:#999;font-size:0.85em;">You received this because you set a booking alert on #{Discourse.current_hostname}. You won't receive further alerts for this event.</p>
        </div>
      HTML
    end

    def booking_open_text
      <<~TEXT
        Booking is now open — #{@event.title}

        Hi #{@user.username},

        You asked to be alerted when booking opened for #{@event.title}.

        #{@event_date ? "Date: #{@event_date}" : ''}
        #{@venue_name ? "Venue: #{@venue_name}" : ''}

        View the event and book your place:
        #{@event_url}

        You won't receive further alerts for this event.
      TEXT
    end
  end
end
