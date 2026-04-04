import Route from "@ember/routing/route";
import { ajax } from "discourse/lib/ajax";

export default class BookingCancelRoute extends Route {
  async model(params) {
    await ajax(`/des/bookings/${params.booking_id}/cancel.json`, {
      type: "POST",
    });
    return { booking_id: params.booking_id };
  }
}
