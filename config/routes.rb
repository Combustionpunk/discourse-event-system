# frozen_string_literal: true

DiscourseEventSystem::Engine.routes.draw do
  # Frontend routes
  get "/events" => "frontend#index"
  get "/events/:id/manage" => "frontend#index"
  get "/events/:id" => "frontend#index"
  get "/events/booking/:booking_id/confirm" => "frontend#index"
  get "/events/booking/:booking_id/cancel" => "frontend#index"
  get "/my-bookings" => "frontend#index"
  get "/organisations" => "frontend#index"
  get "/organisations/new" => "frontend#index"
  get "/organisations/:id" => "frontend#index"
  get "/des-admin" => "frontend#index"
  get "/racing-profile" => "frontend#index"
  get "/my-garage" => "frontend#index"
  get "/events/new" => "frontend#index"

  # API routes
  get "/des/class-types" => "events#class_types"
  get "/des/event-types" => "events#event_types"
  get "/des/events/by-topic/:topic_id" => "events#by_topic"
  get "/des/events" => "events#index"
  get "/des/events/:id" => "events#show"
  post "/des/events" => "events#create"
  put "/des/events/:id" => "events#update"
  post "/des/events/:id/publish" => "events#publish"
  post "/des/events/:id/cancel" => "events#cancel"
  get "/des/events/:id/entrants" => "events#entrants"

  get "/des/bookings" => "bookings#index"
  post "/des/waitlist" => "bookings#join_waitlist"
  delete "/des/waitlist/:id" => "bookings#leave_waitlist"
  get "/des/waitlist" => "bookings#my_waitlist"
  get "/des/bookings/eligible-cars" => "bookings#eligible_cars"
  get "/des/bookings/:id" => "bookings#show"
  post "/des/bookings" => "bookings#create"
  post "/des/bookings/:id/confirm" => "bookings#confirm"
  post "/des/bookings/:id/cancel" => "bookings#cancel"
  post "/des/bookings/:id/refund" => "bookings#refund"
  post "/des/bookings/:id/add_classes" => "bookings#add_classes"

  get "/des/organisations" => "organisations#index"
  get "/des/organisations/:id" => "organisations#show"
  post "/des/organisations" => "organisations#create"
  put "/des/organisations/:id" => "organisations#update"
  post "/des/organisations/:id/approve" => "organisations#approve"
  post "/des/organisations/:id/reject" => "organisations#reject"
  get "/des/organisations/:id/members" => "organisations#members"
  post "/des/organisations/:id/add_member" => "organisations#add_member"

  get "/des/racing-profile" => "racing_profiles#show"
  put "/des/racing-profile" => "racing_profiles#update"

  get "/des/garage" => "garage#index"
  post "/des/garage" => "garage#create"
  put "/des/garage/:id" => "garage#update"
  delete "/des/garage/:id" => "garage#destroy"
  get "/des/garage/models" => "garage#models"
  post "/des/garage/suggest-manufacturer" => "garage#suggest_manufacturer"
  post "/des/garage/suggest-model" => "garage#suggest_model"

  get "/des/admin" => "admin#index"
  post "/des/admin/organisations/:id/approve" => "admin#approve_organisation"
  post "/des/admin/organisations/:id/reject" => "admin#reject_organisation"
  post "/des/admin/manufacturers/:id/approve" => "admin#approve_manufacturer"
  post "/des/admin/manufacturers/:id/reject" => "admin#reject_manufacturer"
  post "/des/admin/models/:id/approve" => "admin#approve_model"
  post "/des/admin/models/:id/reject" => "admin#reject_model"
  put "/des/admin/models/:id" => "admin#update_model"
end

Discourse::Application.routes.draw do
  mount DiscourseEventSystem::Engine, at: "/"
end
