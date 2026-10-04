export default function () {
  this.route("events" );
  this.route("event-new", { path: "/events/new" });
  this.route("event-manage", { path: "/events/:event_id/manage" });
  this.route("event", { path: "/events/:event_id" });
  this.route("booking-confirm", { path: "/events/booking/:booking_id/confirm" });
  this.route("booking-cancel", { path: "/events/booking/:booking_id/cancel" });
  this.route("my-bookings" );
  this.route("my-memberships" );
  this.route("my-organisations" );
  this.route("organisations" );
  this.route("organisation-new", { path: "/organisations/new" });
  this.route("organisation", { path: "/organisations/:organisation_id" });
  this.route("venues" );
  this.route("venue", { path: "/venues/:venue_id" });
  this.route("des-admin" );
  this.route("racing-profile" );
  this.route("my-garage" );
  this.route("car-models" );
  this.route("car-model", { path: "/car-models/:car_model_id" });
  this.route("membership-confirm", { path: "/memberships/:membership_id/confirm" });
  this.route("membership-cancel", { path: "/memberships/:membership_id/cancel" });
  this.route("family-setup", { path: "/memberships/:membership_id/family-setup" });
  this.route("membership-renew-confirm", { path: "/memberships/:membership_id/renew-confirm" });
}
