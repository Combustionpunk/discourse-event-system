export default function () {
  this.route("events", { path: "/events" });
  this.route("event", { path: "/events/:event_id" });
  this.route("booking-confirm", { path: "/events/booking/:booking_id/confirm" });
  this.route("booking-cancel", { path: "/events/booking/:booking_id/cancel" });
  this.route("my-bookings", { path: "/my-bookings" });
  this.route("organisations", { path: "/organisations" });
  this.route("organisation-new", { path: "/organisations/new" });
  this.route("organisation", { path: "/organisations/:organisation_id" });
  this.route("des-admin", { path: "/des-admin" });
  this.route("racing-profile", { path: "/racing-profile" });
  this.route("my-garage", { path: "/my-garage" });
  this.route("event-new", { path: "/events/new" });
}
