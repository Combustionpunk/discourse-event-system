# frozen_string_literal: true

# name: discourse-event-system
# about: An events plugin with bookings, waitlists, and PayPal payments
# version: 0.1.0
# authors: Your Name
# url: https://github.com/yourname/discourse-event-system

enabled_site_setting :discourse_event_system_enabled

register_editable_user_custom_field :brca_membership_number
register_editable_user_custom_field :des_date_of_birth

module ::DiscourseEventSystem
  PLUGIN_NAME = "discourse-event-system"
end

require_relative "lib/discourse_event_system/engine"

after_initialize do
  load File.expand_path("../app/models/des_position.rb", __FILE__)
  load File.expand_path("../app/models/des_organisation.rb", __FILE__)
  load File.expand_path("../app/models/des_organisation_member.rb", __FILE__)
  load File.expand_path("../app/models/des_event_type.rb", __FILE__)
  load File.expand_path("../app/models/des_event_class_type.rb", __FILE__)
  load File.expand_path("../app/models/des_event.rb", __FILE__)
  load File.expand_path("../app/models/des_event_pricing_rule.rb", __FILE__)
  load File.expand_path("../app/models/des_event_class.rb", __FILE__)
  load File.expand_path("../app/models/des_event_discount.rb", __FILE__)
  load File.expand_path("../app/models/des_event_discount_condition.rb", __FILE__)
  load File.expand_path("../app/models/des_event_booking.rb", __FILE__)
  load File.expand_path("../app/models/des_event_booking_class.rb", __FILE__)
  load File.expand_path("../app/models/des_event_booking_payment.rb", __FILE__)
  load File.expand_path("../app/models/des_event_booking_refund.rb", __FILE__)
  load File.expand_path("../app/models/des_event_waitlist.rb", __FILE__)
  load File.expand_path("../app/models/des_organisation_membership_type.rb", __FILE__)
  load File.expand_path("../app/models/des_organisation_membership.rb", __FILE__)
  load File.expand_path("../app/models/des_membership_payment.rb", __FILE__)
  load File.expand_path("../app/models/des_membership_payout.rb", __FILE__)
  load File.expand_path("../app/models/des_event_payout.rb", __FILE__)
  load File.expand_path("../app/models/des_event_cancellation_refund.rb", __FILE__)
  load File.expand_path("../app/models/des_manufacturer.rb", __FILE__)
  load File.expand_path("../app/models/des_car_model.rb", __FILE__)
  load File.expand_path("../app/models/des_user_car.rb", __FILE__)
  load File.expand_path("../app/models/des_class_compatibility_rule.rb", __FILE__)
  load File.expand_path("../app/services/des_paypal_service.rb", __FILE__)
  load File.expand_path("../app/services/des_booking_service.rb", __FILE__)
  load File.expand_path("../app/controllers/discourse_event_system/events_controller.rb", __FILE__)
  load File.expand_path("../app/controllers/discourse_event_system/bookings_controller.rb", __FILE__)
  load File.expand_path("../app/controllers/discourse_event_system/organisations_controller.rb", __FILE__)
  load File.expand_path("../app/controllers/discourse_event_system/frontend_controller.rb", __FILE__)
  load File.expand_path("../app/controllers/discourse_event_system/racing_profiles_controller.rb", __FILE__)
  load File.expand_path("../app/controllers/discourse_event_system/garage_controller.rb", __FILE__)
  load File.expand_path("../app/controllers/discourse_event_system/admin_controller.rb", __FILE__)
  load File.expand_path("../app/mailers/event_mailer.rb", __FILE__)
  load File.expand_path("../db/seeds.rb", __FILE__) if DesPosition.count == 0
end
