# frozen_string_literal: true

# name: discourse-event-system
# about: An events plugin with bookings, waitlists, and PayPal payments
# version: 0.1.0
# authors: Your Name
# url: https://github.com/yourname/discourse-event-system

enabled_site_setting :discourse_event_system_enabled

register_editable_user_custom_field :brca_membership_number
register_editable_user_custom_field :des_date_of_birth
register_editable_user_custom_field :des_f_grade
register_editable_user_custom_field :des_t_grade
register_editable_user_custom_field :des_postcode

module ::DiscourseEventSystem
  PLUGIN_NAME = "discourse-event-system"
end

require_relative "lib/discourse_event_system/engine"

register_asset "stylesheets/discourse-event-system.scss"
register_asset "stylesheets/common/des-results.scss"
register_asset "stylesheets/common/des-car-models.scss"
register_asset "stylesheets/common/rc-events-list.scss"

after_initialize do
  # Members may only suggest car models and box art; everything else goes through this.
  add_to_class(:guardian, :can_edit_car_models?) { is_admin? }

  require_relative "app/models/des_position"
  require_relative "app/models/des_organisation"
  require_relative "app/models/des_organisation_member"
  require_relative "app/models/des_event_type"
  require_relative "app/models/des_event_class_type"
  require_relative "app/models/des_event"
  require_relative "app/models/des_event_pricing_rule"
  require_relative "app/models/des_event_class"
  require_relative "app/models/des_event_discount"
  require_relative "app/models/des_event_discount_condition"
  require_relative "app/models/des_event_booking"
  require_relative "app/models/des_event_booking_class"
  require_relative "app/models/des_event_booking_payment"
  require_relative "app/models/des_event_booking_refund"
  require_relative "app/models/des_event_waitlist"
  require_relative "app/models/des_organisation_membership_type"
  require_relative "app/models/des_organisation_membership"
  require_relative "app/models/des_membership_payment"
  require_relative "app/models/des_membership_payout"
  require_relative "app/models/des_event_payout"
  require_relative "app/models/des_event_cancellation_refund"
  require_relative "app/models/des_manufacturer"
  require_relative "app/models/des_car_model"
  require_relative "app/models/des_car_model_image_suggestion"
  require_relative "app/models/des_user_car"
  require_relative "app/models/des_class_compatibility_rule"
  require_relative "app/models/des_event_booking_alert"
  require_relative "app/models/des_imported_event"
  require_relative "app/models/des_venue_suggestion"
  require_relative "app/models/des_venue_track"
  require_relative "app/services/des_paypal_service"
  require_relative "app/services/des_booking_service"
  require_relative "app/services/des_car_model_merge_service"
  require_relative "app/services/des_car_model_name_tidier"
  require_relative "app/controllers/discourse_event_system/events_controller"
  require_relative "app/controllers/discourse_event_system/bookings_controller"
  require_relative "app/controllers/discourse_event_system/organisations_controller"
  require_relative "app/controllers/discourse_event_system/frontend_controller"
  require_relative "app/controllers/discourse_event_system/racing_profiles_controller"
  require_relative "app/controllers/discourse_event_system/garage_controller"
  require_relative "app/controllers/discourse_event_system/admin_controller"
  require_relative "app/controllers/discourse_event_system/car_models_controller"
  require_relative "app/controllers/discourse_event_system/payouts_controller"
  require_relative "app/mailers/discourse_event_system/event_mailer"
  require_relative "app/mailers/discourse_event_system/booking_alert_mailer"
  require_relative "app/jobs/scheduled/membership_expiry_check"
  require_relative "app/jobs/scheduled/check_booking_alerts"
  require_relative "app/jobs/regular/discourse_event_system_geocode_venue"
  require_relative "app/jobs/scheduled/brca_calendar_sync"
  require_relative "app/models/des_membership_family_member"
  require_relative "app/models/des_racing_family_member"
  require_relative "db/seeds" if DesPosition.count == 0

  # Auto-create events category if it doesn't exist
  on(:site_settings_changed) do |changes|
    next if changes.exclude?(:discourse_event_system_category_slug)
  end

  # In development with Ember CLI on port 4200, PayPal return URLs must point
  # to 4200 (not 3000) so the session cookie is valid on redirect back.
  if Rails.env.development? && SiteSetting.port.blank?
    SiteSetting.port = 4200
    Rails.logger.info "Set SiteSetting.port to 4200 for PayPal return URLs (Ember CLI)"
  end

  begin
    category_name = SiteSetting.discourse_event_system_category_name
    category_slug = SiteSetting.discourse_event_system_category_slug
    unless Category.find_by(slug: category_slug)
      Category.create!(
        name: category_name,
        slug: category_slug,
        user: Discourse.system_user,
        color: "0088CC",
        text_color: "FFFFFF",
        description: "#{category_name} - Book your place at upcoming events"
      )
      Rails.logger.info "Created #{category_name} category"
    end
  rescue => e
    Rails.logger.error "Failed to create events category: #{e.message}"
  end

  # Load badge service
  require_relative "app/services/des_payout_service"
  require_relative "app/services/des_badge_service"

  # Create RC racing badges
  begin
    badge_defs = [
      { name: "First Start", type_id: 3, icon: "flag-checkered", desc: "Completed your first race booking" },
      { name: "Regular Racer", type_id: 2, icon: "flag-checkered", desc: "10 confirmed race bookings" },
      { name: "Seasoned Racer", type_id: 2, icon: "trophy", desc: "25 confirmed race bookings" },
      { name: "Veteran Racer", type_id: 1, icon: "trophy", desc: "50 confirmed race bookings" },
      { name: "Elite Racer", type_id: 1, icon: "star", desc: "100 confirmed race bookings" },
      { name: "Pit Crew", type_id: 3, icon: "wrench", desc: "Added your first car to the garage" },
      { name: "Club Member", type_id: 3, icon: "id-card", desc: "Joined your first organisation" },
      { name: "Family Racer", type_id: 3, icon: "users", desc: "Added a family member or dependant" },
    ]
    badge_defs.each do |bd|
      Badge.find_or_create_by!(name: bd[:name]) do |b|
        b.badge_type_id = bd[:type_id]
        b.description = bd[:desc]
        b.long_description = bd[:desc]
        b.icon = bd[:icon]
        b.allow_title = false
        b.multiple_grant = false
        b.listable = true
        b.enabled = true
        b.auto_revoke = false
        b.show_posts = false
        b.target_posts = false
        b.system = false
      end
    end
  rescue => e
    Rails.logger.error "Failed to create RC racing badges: #{e.message}"
  end

end
