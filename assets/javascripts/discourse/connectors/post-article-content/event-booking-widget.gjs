import Component from "@glimmer/component";
import { service } from "@ember/service";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { on } from "@ember/modifier";
import { fn } from "@ember/helper";
import { eq } from "truth-helpers";

export default class EventBookingWidget extends Component {
  @service currentUser;
  @tracked event = null;
  @tracked selectedClasses = [];
  @tracked isLoading = true;
  @tracked isBooking = false;
  @tracked showCarSelection = false;
  @tracked eligibleCars = [];
  @tracked carSelections = {};

  constructor() {
    super(...arguments);
    this.loadEvent();
  }

  async loadEvent() {
    try {
      const post = this.args.outletArgs?.post;
      if (!post?.firstPost) return;
      const topicId = post?.topic?.id;
      if (!topicId) return;
      const response = await ajax("/des/events/by-topic/" + topicId + ".json");
      this.event = response;
    } catch (e) {
      // No event for this topic
    } finally {
      this.isLoading = false;
    }
  }

  get calculatedTotal() {
    if (!this.event?.pricing || !this.selectedClasses.length) return 0;
    const pricing = this.event.pricing;
    if (pricing.rule_type === "tiered") {
      const first = parseFloat(pricing.first_class_price);
      const subsequent = parseFloat(pricing.subsequent_class_price);
      const count = this.selectedClasses.length;
      return count === 1 ? first : first + subsequent * (count - 1);
    }
    return parseFloat(pricing.flat_price || 0) * this.selectedClasses.length;
  }

  get allCarsSelected() {
    return this.eligibleCars.length > 0 &&
      this.eligibleCars.every(cls => this.carSelections[cls.class_id]);
  }

  @action
  toggleClass(classId) {
    if (this.selectedClasses.includes(classId)) {
      this.selectedClasses = this.selectedClasses.filter(id => id !== classId);
    } else {
      this.selectedClasses = [...this.selectedClasses, classId];
    }
  }

  @action
  async bookNow() {
    if (!this.selectedClasses.length) return;
    try {
      const response = await ajax("/des/bookings/eligible-cars.json", {
        data: { event_id: this.event.id, class_ids: this.selectedClasses },
      });
      this.eligibleCars = response.classes;
      this.carSelections = {};
      response.classes.forEach(cls => {
        if (cls.eligible_cars.length === 1) {
          this.carSelections = { ...this.carSelections, [cls.class_id]: cls.eligible_cars[0].id };
        }
      });
      this.showCarSelection = true;
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  selectCar(classId, event) {
    this.carSelections = { ...this.carSelections, [classId]: event.target.value };
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
          event_id: this.event.id,
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

  @action
  async joinWaitlist(classId) {
    try {
      const response = await ajax("/des/waitlist.json", {
        type: "POST",
        data: { event_id: this.event.id, event_class_id: classId },
      });
      alert("Added to waitlist at position " + response.position + "!");
    } catch (error) {
      popupAjaxError(error);
    }
  }

  <template>
    {{#if this.event}}
      <div class="event-booking-widget">
        <div class="event-booking-widget-header">
          <h3>🏁 Book Your Place</h3>
        </div>

        <div class="event-classes-booking">
          {{#each this.event.classes as |cls|}}
            <div class="event-class-booking-row">
              <div class="event-class-booking-info">
                <strong>{{cls.name}}</strong>
                <span class="spaces-badge">
                  {{cls.spaces_remaining}} / {{cls.capacity}} spaces
                </span>
              </div>
              {{#if (eq cls.status "sold_out")}}
                <button
                  class="btn btn-small btn-default"
                  {{on "click" (fn this.joinWaitlist cls.id)}}
                >
                  📋 Join Waitlist
                </button>
              {{else}}
                <label class="class-checkbox">
                  <input
                    type="checkbox"
                    {{on "change" (fn this.toggleClass cls.id)}}
                  />
                  Select
                </label>
              {{/if}}
            </div>
          {{/each}}
        </div>

        {{#if this.selectedClasses.length}}
          <div class="event-booking-summary">
            <span>{{this.selectedClasses.length}} class(es) selected</span>
            <strong>Total: £{{this.calculatedTotal}}</strong>
          </div>
        {{/if}}

        {{#if this.currentUser}}
          <button
            class="btn btn-primary event-book-btn"
            {{on "click" this.bookNow}}
          >
            Book Now
          </button>
        {{else}}
          <a href="/login" class="btn btn-primary">Log in to Book</a>
        {{/if}}

        {{#if this.showCarSelection}}
          <div class="car-selection-overlay">
            <div class="car-selection-modal">
              <h2>Select Your Cars</h2>
              {{#each this.eligibleCars as |cls|}}
                <div class="car-selection-class">
                  <h3>{{cls.class_name}}</h3>
                  {{#if cls.eligible_cars.length}}
                    <select {{on "change" (fn this.selectCar cls.class_id)}}>
                      <option value="">Select car...</option>
                      {{#each cls.eligible_cars as |car|}}
                        <option value={{car.id}}>
                          {{car.friendly_name}} - {{car.driveline}} - {{car.transponder_number}}
                        </option>
                      {{/each}}
                    </select>
                  {{else}}
                    <p class="no-eligible-cars">No eligible cars for this class.</p>
                  {{/if}}
                </div>
              {{/each}}
              <div class="car-selection-actions">
                <button
                  class="btn btn-primary"
                  {{on "click" this.confirmBooking}}
                >
                  {{if this.isBooking "Processing..." "Confirm & Pay"}}
                </button>
                <button class="btn btn-default" {{on "click" this.cancelCarSelection}}>
                  Cancel
                </button>
              </div>
            </div>
          </div>
        {{/if}}
      </div>
    {{/if}}
  </template>
}
