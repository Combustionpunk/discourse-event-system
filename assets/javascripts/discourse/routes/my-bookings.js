import Route from "@ember/routing/route";
import { ajax } from "discourse/lib/ajax";

export default class MyBookingsRoute extends Route {
  async model() {
    const formatDate = (dateStr) => {
      if (!dateStr) return null;
      return new Date(dateStr).toLocaleDateString("en-GB", {
        weekday: "long", year: "numeric", month: "long",
        day: "numeric", hour: "2-digit", minute: "2-digit",
      });
    };

    const [fullBookings, waitlistResponse] = await Promise.all([
      ajax("/des/my-bookings-full.json"),
      ajax("/des/waitlist.json"),
    ]);

    const bookings = fullBookings.bookings || [];
    const now = new Date();
    const upcoming = [];
    const past = [];

    bookings.forEach(b => {
      if (b.event?.start_date) {
        b.event.formatted_date = formatDate(b.event.start_date);
        if (new Date(b.event.start_date) > now) {
          upcoming.push(b);
        } else {
          past.push(b);
        }
      }
    });

    const waitlist = waitlistResponse.waitlist || [];
    waitlist.forEach(w => {
      if (w.event?.start_date) {
        w.event.formatted_date = formatDate(w.event.start_date);
      }
    });

    return { bookings, upcoming, past, waitlist };
  }
}
