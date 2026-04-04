import Controller from "@ember/controller";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { inject as service } from "@ember/service";

export default class MyBookingsController extends Controller {
  @service router;

  @action
  async cancelBooking(bookingId) {
    if (!window.confirm("Are you sure you want to cancel this booking? A refund will be issued if eligible.")) return;
    try {
      await ajax("/des/bookings/" + bookingId + "/cancel.json", {
        type: "POST",
      });
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    }
  }
}
