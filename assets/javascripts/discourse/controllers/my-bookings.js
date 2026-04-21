import Controller from "@ember/controller";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { inject as service } from "@ember/service";
import { tracked } from "@glimmer/tracking";

export default class MyBookingsController extends Controller {
  @service router;
  @tracked changingCarBookingId = null;
  @tracked changingCarClassId = null;
  @tracked changingCarOptions = [];

  formatDate(dateStr) {
    if (!dateStr) return "—";
    return new Date(dateStr).toLocaleDateString("en-GB", {
      day: "numeric", month: "short", year: "numeric",
    });
  }

  isUpcoming(dateStr) {
    return dateStr && new Date(dateStr) > new Date();
  }

  @action
  async cancelBooking(bookingId) {
    if (!window.confirm("Are you sure you want to cancel this booking? A refund will be issued if eligible.")) return;
    try {
      await ajax("/des/bookings/" + bookingId + "/cancel.json", { type: "POST" });
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  async leaveWaitlist(waitlistId) {
    if (!window.confirm("Leave the waitlist for this class?")) return;
    try {
      await ajax("/des/waitlist/" + waitlistId + ".json", { type: "DELETE" });
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  async startChangeCar(booking, bc) {
    this.changingCarBookingId = booking.id;
    this.changingCarClassId = bc.id;
    try {
      const response = await ajax("/des/bookings/eligible-cars.json", {
        data: { event_id: booking.event.id, class_ids: [bc.event_class_id] }
      });
      this.changingCarOptions = response.classes?.[0]?.eligible_cars || [];
    } catch { this.changingCarOptions = []; }
  }

  @action cancelChangeCar() {
    this.changingCarBookingId = null;
    this.changingCarClassId = null;
    this.changingCarOptions = [];
  }

  @action
  async confirmChangeCar(carId) {
    try {
      await ajax("/des/bookings/" + this.changingCarBookingId + "/classes/" + this.changingCarClassId + "/car.json", {
        type: "PUT",
        data: { car_id: carId }
      });
      this.changingCarBookingId = null;
      this.changingCarOptions = [];
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    }
  }
}
