import Route from "@ember/routing/route";
import { ajax } from "discourse/lib/ajax";

export default class BookingConfirmRoute extends Route {
  async model(params) {
    const urlParams = new URLSearchParams(window.location.search);
    const paypalOrderId = urlParams.get("token");

    try {
      if (paypalOrderId) {
        await ajax("/des/bookings/" + params.booking_id + "/confirm.json", {
          type: "POST",
          data: { paypal_order_id: paypalOrderId },
        });
      }
    } catch (e) {
      console.error("Payment confirmation failed:", e);
    }

    const booking = await ajax("/des/bookings/" + params.booking_id + ".json");

    if (booking.event && booking.event.start_date) {
      const date = new Date(booking.event.start_date);
      booking.event.formatted_date = date.toLocaleDateString("en-GB", {
        weekday: "long", year: "numeric", month: "long",
        day: "numeric", hour: "2-digit", minute: "2-digit",
      });
    }

    return booking;
  }
}
