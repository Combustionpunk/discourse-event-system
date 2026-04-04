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

    const [bookingsResponse, waitlistResponse] = await Promise.all([
      ajax("/des/bookings.json"),
      ajax("/des/waitlist.json"),
    ]);

    const bookings = Array.isArray(bookingsResponse) ? bookingsResponse : bookingsResponse.bookings || [];
    bookings.forEach(b => {
      if (b.event && b.event.start_date) {
        b.event.formatted_date = formatDate(b.event.start_date);
      }
    });

    const waitlist = waitlistResponse.waitlist || [];
    waitlist.forEach(w => {
      if (w.event && w.event.start_date) {
        w.event.formatted_date = formatDate(w.event.start_date);
      }
    });

    return { bookings, waitlist };
  }
}
