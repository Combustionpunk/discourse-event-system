import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { on } from "@ember/modifier";
import { fn } from "@ember/helper";
import { eq } from "truth-helpers";
import { service } from "@ember/service";

export default class EventBookingWidget extends Component {
  @service currentUser;
  @tracked event = null;
  @tracked selectedClasses = [];
  @tracked isBooking = false;
  @tracked showCarSelection = false;
  @tracked eligibleCars = [];
  @tracked carSelections = {};
  @tracked showCalendarMenu = false;

  constructor() {
    super(...arguments);
    this.loadEvent();
  }

  async loadEvent() {
    try {
      const topic = this.args.outletArgs?.model;
      if (!topic?.id) return;
      const response = await ajax("/des/events/by-topic/" + topic.id + ".json");
      this.event = response;
      if (response.start_date) {
        const d = new Date(response.start_date);
        this.event.formatted_date = d.toLocaleDateString("en-GB", {
          weekday: "long", year: "numeric", month: "long",
          day: "numeric", hour: "2-digit", minute: "2-digit",
        });
      }
    } catch (e) {
      // No event for this topic - widget won't render
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

  get googleCalendarUrl() {
    const e = this.event;
    if (!e?.start_date) return "#";
    const start = new Date(e.start_date);
    const end = e.end_date ? new Date(e.end_date) : new Date(start.getTime() + 4 * 60 * 60 * 1000);
    const fmt = (d) => d.toISOString().replace(/[-:]/g, "").replace(/\.\d{3}/, "");
    const params = new URLSearchParams({
      action: "TEMPLATE", text: e.title,
      dates: fmt(start) + "/" + fmt(end),
      location: e.location || "",
      details: (e.description || "") + "\n\n" + window.location.origin + "/events/" + e.id
    });
    return "https://calendar.google.com/calendar/render?" + params.toString();
  }

  get outlookCalendarUrl() {
    const e = this.event;
    if (!e?.start_date) return "#";
    const start = new Date(e.start_date).toISOString();
    const end = e.end_date ? new Date(e.end_date).toISOString() : new Date(new Date(e.start_date).getTime() + 4 * 60 * 60 * 1000).toISOString();
    const params = new URLSearchParams({
      rru: "addevent", subject: e.title,
      startdt: start, enddt: end,
      location: e.location || "",
      body: (e.description || "") + "\n\n" + window.location.origin + "/events/" + e.id,
      path: "/calendar/action/compose"
    });
    return "https://outlook.live.com/calendar/0/deeplink/compose?" + params.toString();
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
  toggleCalendarMenu() {
    this.showCalendarMenu = !this.showCalendarMenu;
  }

  @action
  downloadICS() {
    const e = this.event;
    if (!e?.start_date) return;
    const fmt = (d) => new Date(d).toISOString().replace(/[-:]/g, "").replace(/\.\d{3}/, "");
    const start = fmt(e.start_date);
    const end = e.end_date ? fmt(e.end_date) : fmt(new Date(new Date(e.start_date).getTime() + 4 * 60 * 60 * 1000));
    const ics = [
      "BEGIN:VCALENDAR", "VERSION:2.0", "PRODID:-//RC Event System//EN",
      "BEGIN:VEVENT",
      "SUMMARY:" + (e.title || ""),
      "DTSTART:" + start, "DTEND:" + end,
      "LOCATION:" + (e.location || ""),
      "DESCRIPTION:" + (e.description || "").replace(/\n/g, "\\n"),
      "URL:" + window.location.origin + "/events/" + e.id,
      "END:VEVENT", "END:VCALENDAR"
    ].join("\r\n");
    const blob = new Blob([ics], { type: "text/calendar;charset=utf-8" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = (e.title || "event").replace(/[^a-z0-9]/gi, "-").toLowerCase() + ".ics";
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
    this.showCalendarMenu = false;
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
          <h3>🏁 {{this.event.title}}</h3>
        </div>

        <div class="event-widget-details">
          {{#if this.event.formatted_date}}
            <div class="event-widget-detail">📅 {{this.event.formatted_date}}</div>
          {{/if}}
          {{#if this.event.location}}
            <div class="event-widget-detail">📍 {{this.event.location}}</div>
          {{/if}}
          {{#if this.event.organisation}}
            <div class="event-widget-detail">🏢 {{this.event.organisation.name}}</div>
          {{/if}}
          {{#if this.event.google_maps_url}}
            <div class="event-widget-detail">
              <a href={{this.event.google_maps_url}} target="_blank" rel="noopener">🗺️ View on Map</a>
            </div>
          {{/if}}
        </div>

        {{#if this.event.pricing}}
          <div class="event-widget-pricing">
            {{#if (eq this.event.pricing.rule_type "tiered")}}
              <span>First class: £{{this.event.pricing.first_class_price}}</span>
              <span>Additional: £{{this.event.pricing.subsequent_class_price}}</span>
            {{else}}
              <span>£{{this.event.pricing.flat_price}} per class</span>
            {{/if}}
          </div>
        {{/if}}

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

        <div class="event-widget-actions">
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

          <div class="calendar-dropdown-wrapper">
            <button class="btn btn-default" type="button" {{on "click" this.toggleCalendarMenu}}>
              📅 Add to Calendar
            </button>
            {{#if this.showCalendarMenu}}
              <div class="calendar-dropdown">
                <a href="#" class="calendar-dropdown-item" {{on "click" this.downloadICS}}>
                  📅 Download ICS (Apple/Outlook)
                </a>
                <a href={{this.googleCalendarUrl}} class="calendar-dropdown-item" target="_blank" rel="noopener">
                  📅 Google Calendar
                </a>
                <a href={{this.outlookCalendarUrl}} class="calendar-dropdown-item" target="_blank" rel="noopener">
                  📅 Outlook.com
                </a>
              </div>
            {{/if}}
          </div>

          <a href="/events/{{this.event.id}}" class="btn btn-default">
            📋 Full Event Page
          </a>
        </div>

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
