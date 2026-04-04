import Route from "@ember/routing/route";
import { ajax } from "discourse/lib/ajax";

export default class MyBookingsRoute extends Route {
  model() {
    return ajax("/des/bookings.json").then((response) => {
      const bookings = Array.isArray(response) ? response : response.bookings || [];
      return bookings.map((booking) => {
        if (booking.event && booking.event.start_date) {
          const date = new Date(booking.event.start_date);
          booking.event.formatted_date = date.toLocaleDateString("en-GB", {
            weekday: "long",
            year: "numeric",
            month: "long",
            day: "numeric",
            hour: "2-digit",
            minute: "2-digit",
          });
        }
        return booking;
      });
    });
  }
}
