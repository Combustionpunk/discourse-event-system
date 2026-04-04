import Controller from "@ember/controller";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { inject as service } from "@ember/service";

export default class EventController extends Controller {
  @service currentUser;
  @service router;
  @tracked selectedClasses = [];
  @tracked isBooking = false;
  @tracked showCarSelection = false;
  @tracked eligibleCars = [];
  @tracked carSelections = {};

  get calculatedTotal() {
    const pricing = this.model.pricing;
    if (!pricing || this.selectedClasses.length === 0) return 0;
    if (pricing.rule_type === "tiered") {
      const first = parseFloat(pricing.first_class_price);
      const subsequent = parseFloat(pricing.subsequent_class_price);
      const count = this.selectedClasses.length;
      return count === 1 ? first : first + subsequent * (count - 1);
    } else {
      return parseFloat(pricing.flat_price) * this.selectedClasses.length;
    }
  }

  get allCarsSelected() {
    return this.eligibleCars.every(cls => this.carSelections[cls.class_id]);
  }

  @action
  toggleClass(classId) {
    if (this.selectedClasses.includes(classId)) {
      this.selectedClasses = this.selectedClasses.filter((id) => id !== classId);
    } else {
      this.selectedClasses = [...this.selectedClasses, classId];
    }
  }

  @action
  async publishEvent() {
    if (!window.confirm("Publish this event? It will become visible to all users.")) return;
    try {
      await ajax("/des/events/" + this.model.id + "/publish.json", {
        type: "POST",
      });
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  async bookEvent() {
    if (this.selectedClasses.length === 0) return;

    // Check if user has garage cars
    try {
      const response = await ajax("/des/bookings/eligible-cars.json", {
        data: {
          event_id: this.model.id,
          class_ids: this.selectedClasses,
        },
      });

      this.eligibleCars = response.classes;
      this.carSelections = {};

      // Auto-select if only one car eligible per class
      response.classes.forEach(cls => {
        if (cls.eligible_cars.length === 1) {
          this.carSelections = {
            ...this.carSelections,
            [cls.class_id]: cls.eligible_cars[0].id
          };
        }
      });

      this.showCarSelection = true;
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  selectCar(classId, event) {
    this.carSelections = {
      ...this.carSelections,
      [classId]: event.target.value
    };
  }

  @action
  cancelCarSelection() {
    this.showCarSelection = false;
    this.eligibleCars = [];
    this.carSelections = {};
  }

  @action
  async confirmBooking() {
    this.isBooking = true;
    try {
      const response = await ajax("/des/bookings.json", {
        type: "POST",
        data: {
          event_id: this.model.id,
          class_ids: this.selectedClasses,
          car_selections: this.carSelections,
        },
      });
      window.location.href = response.approval_url;
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.isBooking = false;
    }
  }
}
