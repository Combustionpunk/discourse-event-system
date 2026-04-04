import Route from "@ember/routing/route";
import { ajax } from "discourse/lib/ajax";

export default class BookingConfirmRoute extends Route {
  async model(params) {
    // Get the PayPal order ID from the URL query params
    const urlParams = new URLSearchParams(window.location.search);
    const paypalOrderId = urlParams.get("token");

    // Confirm the booking with PayPal
    if (paypalOrderId) {
      await ajax(`/des/bookings/${params.booking_id}/confirm.json`, {
        type: "POST",
        data: { paypal_order_id: paypalOrderId },
      });
    }

    // Return the booking details
    return ajax(`/des/bookings/${params.booking_id}.json`);
  }
}
