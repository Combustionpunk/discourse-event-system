import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { on } from "@ember/modifier";
import { fn } from "@ember/helper";
import { eq, not } from "truth-helpers";
import { service } from "@ember/service";
import { LinkTo } from "@ember/routing";

export default class EventBookingWidget extends Component {
  @service currentUser;
  @tracked event = null;
  @tracked publicEntrants = [];
  @tracked selectedClasses = [];
  @tracked isBooking = false;
  @tracked showCarSelection = false;
  @tracked eligibleCars = [];
  @tracked carSelections = {};
  @tracked familyExpanded = false;
  @tracked familySelections = {};
  @tracked familyEligibleCars = null;
  @tracked familyCarSelections = {};
  @tracked isWhosComingExpanded = false;
  @tracked showCalendarDropdown = false;
  @tracked entrantsFilter = "all";

  constructor() {
    super(...arguments);
    this.loadEvent();
  }

  async loadEvent() {
    try {
      const topic = this.args.outletArgs?.model;
      if (!topic?.id) return;
      const response = await ajax("/des/events/by-topic/" + topic.id + ".json");
      if (response.start_date) {
        const d = new Date(response.start_date);
        response.formatted_date = d.toLocaleDateString("en-GB", {
          weekday: "long", year: "numeric", month: "long",
          day: "numeric", hour: "2-digit", minute: "2-digit",
        });
      }
      this.event = response;
      this.loadEntrants(response.id);
    } catch (e) {
      // No event for this topic
    }
  }

  async loadEntrants(eventId) {
    try {
      const data = await ajax("/des/events/" + eventId + "/public-entrants.json");
      const statusOrder = { confirmed: 0, pending: 1, waitlist: 2, cancelled: 3 };
      this.publicEntrants = (data.classes || []).map(cls => {
        const sorted = (cls.entrants || []).slice().sort((a, b) => {
          const sa = statusOrder[a.status] ?? 99;
          const sb = statusOrder[b.status] ?? 99;
          if (sa !== sb) return sa - sb;
          return a.username.localeCompare(b.username);
        });
        return { id: cls.id, name: cls.name, entrants: sorted };
      });
    } catch {
      this.publicEntrants = [];
    }
  }

  // --- Pricing ---

  _calcForClasses(count, isMember, isJunior) {
    const p = this.event?.pricing;
    if (!p || count === 0) return 0;
    let fd = 0, sd = 0;
    if (isMember) { fd += parseFloat(p.member_first_class_discount || 0); sd += parseFloat(p.member_subsequent_discount || 0); }
    if (isJunior) { fd += parseFloat(p.junior_first_class_discount || 0); sd += parseFloat(p.junior_subsequent_discount || 0); }
    if (p.rule_type === "tiered") {
      const first = Math.max(parseFloat(p.first_class_price) - fd, 0);
      const sub = Math.max(parseFloat(p.subsequent_class_price) - sd, 0);
      return count === 1 ? first : first + sub * (count - 1);
    }
    const base = parseFloat(p.flat_price);
    const first = Math.max(base - fd, 0);
    const sub = Math.max(base - sd, 0);
    return count === 1 ? first : first + sub * (count - 1);
  }

  get calculatedTotal() {
    if (!this.event?.pricing) return 0;
    const isMember = this.event.user_is_member || false;
    const isJunior = this.event.user_is_junior || false;
    let total = this._calcForClasses(this.selectedClasses.length, isMember, isJunior);
    Object.keys(this.familySelections).forEach(uid => {
      const ids = this.familySelections[uid] || [];
      if (ids.length > 0) total += this._calcForClasses(ids.length, isMember, false);
    });
    return total;
  }

  get totalClassCount() {
    let c = this.selectedClasses.length;
    Object.values(this.familySelections).forEach(ids => { c += (ids || []).length; });
    return c;
  }

  get hasFamilySelections() {
    return Object.values(this.familySelections).some(ids => ids && ids.length > 0);
  }

  get noClassesSelected() {
    return this.selectedClasses.length === 0 && !this.hasFamilySelections;
  }

  get allCarsSelected() {
    if (!this.eligibleCars.every(cls => this.carSelections[cls.class_id])) return false;
    if (this.familyEligibleCars) {
      for (const entry of this.familyEligibleCars) {
        for (const cls of entry.classes) {
          if (!this.familyCarSelections[`${entry.user_id}_${cls.class_id}`]) return false;
        }
      }
    }
    return true;
  }


  get bookingClosed() {
    if (!this.event?.booking_closing_date) return false;
    return new Date(this.event.booking_closing_date) < new Date();
  }

  get bookingDisabled() {
    return this.event?.status === "cancelled" || this.bookingClosed;
  }

  get totalEntrantCount() {
    let c = 0;
    this.publicEntrants.forEach(cls => { c += (cls.entrants || []).length; });
    return c;
  }


  get filteredEntrants() {
    if (this.entrantsFilter === "all") return this.publicEntrants;
    return this.publicEntrants.map(cls => ({
      ...cls,
      entrants: cls.entrants.filter(e => e.status === this.entrantsFilter)
    }));
  }

  get entrantsStatusCounts() {
    const counts = { all: 0, confirmed: 0, pending: 0, cancelled: 0, waitlist: 0 };
    this.publicEntrants.forEach(cls => {
      (cls.entrants || []).forEach(e => {
        counts.all++;
        if (counts[e.status] !== undefined) counts[e.status]++;
      });
    });
    return counts;
  }

  // --- Calendar ---

  get googleCalendarUrl() {
    const e = this.event;
    if (!e?.start_date) return "#";
    const start = new Date(e.start_date);
    const end = e.end_date ? new Date(e.end_date) : new Date(start.getTime() + 4*3600000);
    const fmt = (d) => d.toISOString().replace(/[-:]/g, "").replace(/\.\d{3}/, "");
    const p = new URLSearchParams({ action: "TEMPLATE", text: e.title, dates: fmt(start)+"/"+fmt(end), location: e.location||"", details: (e.description||"")+"\n\n"+window.location.origin+"/events/"+e.id });
    return "https://calendar.google.com/calendar/render?" + p.toString();
  }

  get outlookCalendarUrl() {
    const e = this.event;
    if (!e?.start_date) return "#";
    const start = new Date(e.start_date).toISOString();
    const end = e.end_date ? new Date(e.end_date).toISOString() : new Date(new Date(e.start_date).getTime()+4*3600000).toISOString();
    const p = new URLSearchParams({ rru: "addevent", subject: e.title, startdt: start, enddt: end, location: e.location||"", body: (e.description||"")+"\n\n"+window.location.origin+"/events/"+e.id, path: "/calendar/action/compose" });
    return "https://outlook.live.com/calendar/0/deeplink/compose?" + p.toString();
  }

  // --- Actions ---

  @action toggleClass(classId) {
    if (this.selectedClasses.includes(classId)) {
      this.selectedClasses = this.selectedClasses.filter(id => id !== classId);
    } else {
      const max = this.event.max_classes_per_booking;
      if (max && this.selectedClasses.length >= max) {
        alert("You can only select a maximum of " + max + " class(es) for this event.");
        return;
      }
      this.selectedClasses = [...this.selectedClasses, classId];
    }
  }

  @action toggleFamilySection() { this.familyExpanded = !this.familyExpanded; }

  @action toggleFamilyClass(userId, classId) {
    const c = { ...this.familySelections };
    const uc = c[userId] || [];
    c[userId] = uc.includes(classId) ? uc.filter(id => id !== classId) : [...uc, classId];
    this.familySelections = c;
  }

  @action toggleWhosComingSection() { this.isWhosComingExpanded = !this.isWhosComingExpanded; }
  @action setEntrantsFilter(filter) { this.entrantsFilter = filter; }
  @action toggleCalendarDropdown() { this.showCalendarDropdown = !this.showCalendarDropdown; }

  @action downloadICS() {
    const e = this.event;
    if (!e?.start_date) return;
    const fmt = (d) => new Date(d).toISOString().replace(/[-:]/g, "").replace(/\.\d{3}/, "");
    const s = fmt(e.start_date);
    const n = e.end_date ? fmt(e.end_date) : fmt(new Date(new Date(e.start_date).getTime()+4*3600000));
    const ics = ["BEGIN:VCALENDAR","VERSION:2.0","PRODID:-//RC Event System//EN","BEGIN:VEVENT","SUMMARY:"+(e.title||""),"DTSTART:"+s,"DTEND:"+n,"LOCATION:"+(e.location||""),"DESCRIPTION:"+(e.description||"").replace(/\n/g,"\\n"),"URL:"+window.location.origin+"/events/"+e.id,"END:VEVENT","END:VCALENDAR"].join("\r\n");
    const blob = new Blob([ics], { type: "text/calendar;charset=utf-8" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url; a.download = (e.title||"event").replace(/[^a-z0-9]/gi, "-").toLowerCase()+".ics";
    document.body.appendChild(a); a.click(); document.body.removeChild(a);
    URL.revokeObjectURL(url);
    this.showCalendarDropdown = false;
  }

  @action async joinWaitlist(classId) {
    if (!this.currentUser) { alert("Please log in to join the waitlist"); return; }
    try {
      const r = await ajax("/des/waitlist.json", { type: "POST", data: { event_id: this.event.id, event_class_id: classId } });
      alert("Added to waitlist at position " + r.position + "!");
    } catch (error) { popupAjaxError(error); }
  }

  @action async bookEvent() {
    if (this.selectedClasses.length === 0 && !this.hasFamilySelections) return;
    try {
      const response = await ajax("/des/bookings/eligible-cars.json", { data: { event_id: this.event.id, class_ids: this.selectedClasses } });
      this.eligibleCars = response.classes;
      this.carSelections = {};
      response.classes.forEach(cls => {
        if (cls.eligible_cars.length === 1) this.carSelections = { ...this.carSelections, [cls.class_id]: cls.eligible_cars[0].id };
      });
      this.familyEligibleCars = null;
      this.familyCarSelections = {};
      if (this.hasFamilySelections) {
        const entries = [];
        for (const uid of Object.keys(this.familySelections)) {
          const cids = this.familySelections[uid];
          if (cids && cids.length > 0) {
            const fr = await ajax("/des/bookings/eligible-cars.json", { data: { event_id: this.event.id, class_ids: cids } });
            const member = (this.event.family_members||[]).find(m => String(m.user_id)===String(uid));
            entries.push({ user_id: uid, username: member ? member.username : `User ${uid}`, classes: fr.classes });
            fr.classes.forEach(cls => {
              if (cls.eligible_cars.length === 1) this.familyCarSelections = { ...this.familyCarSelections, [`${uid}_${cls.class_id}`]: cls.eligible_cars[0].id };
            });
          }
        }
        this.familyEligibleCars = entries;
      }
      this.showCarSelection = true;
    } catch (error) { popupAjaxError(error); }
  }

  @action selectCar(classId, event) { this.carSelections = { ...this.carSelections, [classId]: event.target.value }; }
  @action selectFamilyCar(userId, classId, event) { this.familyCarSelections = { ...this.familyCarSelections, [`${userId}_${classId}`]: event.target.value }; }

  @action cancelCarSelection() {
    this.showCarSelection = false; this.eligibleCars = []; this.carSelections = {};
    this.familyEligibleCars = null; this.familyCarSelections = {};
  }

  @action async confirmBooking() {
    this.isBooking = true;
    try {
      const data = { event_id: this.event.id, class_ids: this.selectedClasses, car_selections: this.carSelections };
      if (this.hasFamilySelections) {
        const fb = {}; let idx = 0;
        Object.keys(this.familySelections).forEach(uid => {
          const cids = this.familySelections[uid];
          if (cids && cids.length > 0) {
            const mcs = {};
            cids.forEach(cid => { const k = `${uid}_${cid}`; if (this.familyCarSelections[k]) mcs[cid] = this.familyCarSelections[k]; });
            fb[idx] = { user_id: uid, class_ids: cids, car_selections: mcs }; idx++;
          }
        });
        data.family_bookings = fb;
      }
      const response = await ajax("/des/bookings.json", { type: "POST", data });
      window.location.href = response.approval_url;
    } catch (error) { popupAjaxError(error); } finally { this.isBooking = false; }
  }

  <template>
    {{#if this.event}}
      <div class="event-detail-container event-topic-widget">

        <div class="event-detail-meta">
          <div class="event-detail-meta-item">
            <strong>Organisation:</strong> {{this.event.organisation.name}}
          </div>
          <div class="event-detail-meta-item">
            <strong>Date:</strong> {{this.event.formatted_date}}
          </div>
          {{#if this.event.location}}
            <div class="event-detail-meta-item">
              <strong>Location:</strong> {{this.event.location}}
            </div>
          {{/if}}
          {{#if this.event.google_maps_url}}
            <div class="event-detail-meta-item">
              <a href={{this.event.google_maps_url}} target="_blank" rel="noopener">📍 View on Google Maps</a>
            </div>
          {{/if}}
        </div>


        {{#if (eq this.event.status "cancelled")}}
          <div class="event-cancelled-banner">⚠️ This event has been cancelled.</div>
        {{else if this.bookingClosed}}
          <div class="event-closed-banner">⏰ Booking has closed for this event.</div>
        {{/if}}

        {{#unless this.bookingDisabled}}
        <div class="event-detail-classes">
          <h3>Classes</h3>
          <div class="event-classes-grid">
            {{#each this.event.classes as |cls|}}
              <div class="event-class-card {{if (eq cls.status 'sold_out') 'sold-out'}}">
                <div class="event-class-name">{{cls.name}}</div>
                <div class="event-class-spaces">{{cls.spaces_remaining}} / {{cls.capacity}} spaces</div>
                {{#if (eq cls.status "sold_out")}}
                  <button class="btn btn-small btn-default" {{on "click" (fn this.joinWaitlist cls.id)}}>📋 Join Waitlist</button>
                {{else}}
                  <input type="checkbox" id="topic-class-{{cls.id}}" {{on "change" (fn this.toggleClass cls.id)}} />
                  <label for="topic-class-{{cls.id}}">Select</label>
                {{/if}}
              </div>
            {{/each}}
          </div>
        </div>

        {{#if this.event.max_classes_per_booking}}
          <p class="field-help">⚠️ Maximum {{this.event.max_classes_per_booking}} class(es) per booking.</p>
        {{/if}}

        {{#if this.event.pricing}}
          <div class="event-detail-pricing">
            <h3>Pricing</h3>
            {{#if (eq this.event.pricing.rule_type "tiered")}}
              <p>First class: £{{this.event.pricing.first_class_price}}</p>
              <p>Additional classes: £{{this.event.pricing.subsequent_class_price}} each</p>
            {{else}}
              <p>£{{this.event.pricing.flat_price}} per class</p>
            {{/if}}
            {{#if this.selectedClasses.length}}
              <div class="event-booking-summary">
                <strong>Selected: {{this.selectedClasses.length}} classes</strong>
                <strong>Total: £{{this.calculatedTotal}}</strong>
              </div>
            {{/if}}
          </div>
        {{/if}}

        {{!-- Family Booking --}}
        {{#if this.event.family_members.length}}
          <div class="event-family-booking">
            <button class="btn btn-default family-toggle" {{on "click" this.toggleFamilySection}}>
              {{if this.familyExpanded "▼" "▶"}} Book Family Members
            </button>
            {{#if this.familyExpanded}}
              <div class="family-members-list">
                {{#each this.event.family_members as |member|}}
                  <div class="family-member-card">
                    <h4>{{member.username}}</h4>
                    <div class="event-classes-grid">
                      {{#each this.event.classes as |cls|}}
                        <div class="event-class-card {{if (eq cls.status 'sold_out') 'sold-out'}}">
                          <div class="event-class-name">{{cls.name}}</div>
                          <div class="event-class-spaces">{{cls.spaces_remaining}} / {{cls.capacity}} spaces</div>
                          {{#if (eq cls.status "sold_out")}}
                            <span class="field-help">Sold out</span>
                          {{else}}
                            <input type="checkbox" id="topic-family-{{member.user_id}}-class-{{cls.id}}" {{on "change" (fn this.toggleFamilyClass member.user_id cls.id)}} />
                            <label for="topic-family-{{member.user_id}}-class-{{cls.id}}">Select</label>
                          {{/if}}
                        </div>
                      {{/each}}
                    </div>
                  </div>
                {{/each}}
              </div>
            {{/if}}
          </div>
        {{/if}}

        {{!-- Family summary --}}
        {{#if this.event.pricing}}
          {{#if this.hasFamilySelections}}
            <div class="event-booking-summary family-summary">
              <strong>Combined Total (you + family): {{this.totalClassCount}} classes</strong>
              <strong>Total: £{{this.calculatedTotal}}</strong>
            </div>
          {{/if}}
        {{/if}}

        <div class="event-detail-actions">
          {{#if this.currentUser}}
            <button class="btn btn-primary" disabled={{this.noClassesSelected}} {{on "click" this.bookEvent}}>
              {{if this.isBooking "Processing..." "Book Now"}}
            </button>
          {{else}}
            <a href="/login" class="btn btn-primary">Log in to Book</a>
          {{/if}}

          <div class="calendar-dropdown-wrapper">
            <button class="btn btn-default" type="button" {{on "click" this.toggleCalendarDropdown}}>📅 Add to Calendar</button>
            {{#if this.showCalendarDropdown}}
              <div class="calendar-dropdown">
                <a href="#" class="calendar-dropdown-item" {{on "click" this.downloadICS}}>📅 Download ICS (Apple/Outlook)</a>
                <a href={{this.googleCalendarUrl}} class="calendar-dropdown-item" target="_blank" rel="noopener">📅 Google Calendar</a>
                <a href={{this.outlookCalendarUrl}} class="calendar-dropdown-item" target="_blank" rel="noopener">📅 Outlook.com</a>
              </div>
            {{/if}}
          </div>

          {{#if this.event.is_admin}}
            <a href="/events/{{this.event.id}}/manage" class="btn btn-default">⚙️ Manage Event</a>
          {{/if}}

          <a href="/events/{{this.event.id}}" class="btn btn-default">📋 Full Event Page</a>
        </div>
        {{/unless}}

        {{!-- Who's Coming --}}
        {{#if this.totalEntrantCount}}
          <div class="event-whos-coming">
            <button class="whos-coming-toggle" type="button" {{on "click" this.toggleWhosComingSection}}>
              <span class="whos-coming-chevron">{{if this.isWhosComingExpanded "▼" "▶"}}</span>
              <h3>👥 Who's Coming? ({{this.totalEntrantCount}} entries)</h3>
            </button>
            {{#if this.isWhosComingExpanded}}
              <div class="entrants-filters">
                <button class="btn btn-small {{if (eq this.entrantsFilter 'all') 'btn-primary' 'btn-default'}}" {{on "click" (fn this.setEntrantsFilter "all")}}>All ({{this.entrantsStatusCounts.all}})</button>
                <button class="btn btn-small {{if (eq this.entrantsFilter 'confirmed') 'btn-primary' 'btn-default'}}" {{on "click" (fn this.setEntrantsFilter "confirmed")}}>✅ Confirmed ({{this.entrantsStatusCounts.confirmed}})</button>
                <button class="btn btn-small {{if (eq this.entrantsFilter 'pending') 'btn-primary' 'btn-default'}}" {{on "click" (fn this.setEntrantsFilter "pending")}}>⏳ Pending ({{this.entrantsStatusCounts.pending}})</button>
                <button class="btn btn-small {{if (eq this.entrantsFilter 'cancelled') 'btn-primary' 'btn-default'}}" {{on "click" (fn this.setEntrantsFilter "cancelled")}}>❌ Cancelled ({{this.entrantsStatusCounts.cancelled}})</button>
              </div>
              {{#each this.filteredEntrants as |cls|}}
                {{#if cls.entrants.length}}
                  <div class="entrants-class">
                    <h4>{{cls.name}}</h4>
                    <table class="entrants-table entrants-table--public">
                      <thead>
                        <tr>
                          <th class="avatar-col"></th>
                          <th>Username</th>
                          <th>Manufacturer</th>
                          <th>Model</th>
                          <th>Transponder</th>
                          <th>BRCA No.</th>
                          <th>Status</th>
                        </tr>
                      </thead>
                      <tbody>
                        {{#each cls.entrants as |entrant|}}
                          <tr class="entrant-row entrant-row--{{entrant.status}}">
                            <td class="avatar-col"><a data-user-card={{entrant.username}}><img src="{{entrant.avatar_template}}" class="entrant-avatar" alt="" /></a></td>
                            <td>{{entrant.username}}</td>
                            <td>{{entrant.manufacturer_name}}</td>
                            <td>{{entrant.model_name}}</td>
                            <td class="transponder-number">{{entrant.transponder}}</td>
                            <td>{{entrant.brca_number}}</td>
                            <td><span class="booking-status booking-status--{{entrant.status}}">{{entrant.status}}</span></td>
                          </tr>
                        {{/each}}
                      </tbody>
                    </table>
                  </div>
                {{/if}}
              {{/each}}
            {{/if}}
          </div>
        {{/if}}

        {{!-- Car Selection Modal --}}
        {{#if this.showCarSelection}}
          <div class="car-selection-overlay">
            <div class="car-selection-modal">
              <h2>Select Cars</h2>
              <p class="field-help">Select which car to enter for each class.</p>
              <h3>Your Classes</h3>
              {{#each this.eligibleCars as |cls|}}
                <div class="car-selection-class">
                  <h4>{{cls.class_name}}</h4>
                  {{#if cls.eligible_cars.length}}
                    <select {{on "change" (fn this.selectCar cls.class_id)}}>
                      <option value="">Select car...</option>
                      {{#each cls.eligible_cars as |car|}}
                        <option value={{car.id}}>{{car.friendly_name}} — {{car.driveline}} — {{car.transponder_number}}{{#if car.owner_username}} ({{car.owner_username}}){{/if}}</option>
                      {{/each}}
                    </select>
                  {{else}}
                    <div class="no-eligible-cars">No eligible cars in your garage for this class. <a href="/my-garage">Add a car</a></div>
                  {{/if}}
                </div>
              {{/each}}
              {{#if this.familyEligibleCars}}
                {{#each this.familyEligibleCars as |entry|}}
                  <h3>{{entry.username}}</h3>
                  {{#each entry.classes as |cls|}}
                    <div class="car-selection-class">
                      <h4>{{cls.class_name}}</h4>
                      {{#if cls.eligible_cars.length}}
                        <select {{on "change" (fn this.selectFamilyCar entry.user_id cls.class_id)}}>
                          <option value="">Select car...</option>
                          {{#each cls.eligible_cars as |car|}}
                            <option value={{car.id}}>{{car.friendly_name}} — {{car.driveline}} — {{car.transponder_number}}{{#if car.owner_username}} ({{car.owner_username}}){{/if}}</option>
                          {{/each}}
                        </select>
                      {{else}}
                        <div class="no-eligible-cars">No eligible cars for this class.</div>
                      {{/if}}
                    </div>
                  {{/each}}
                {{/each}}
              {{/if}}
              <div class="car-selection-actions">
                <button class="btn btn-primary" {{on "click" this.confirmBooking}}>{{if this.isBooking "Processing..." "Confirm & Pay"}}</button>
                <button class="btn btn-default" {{on "click" this.cancelCarSelection}}>Cancel</button>
              </div>
            </div>
          </div>
        {{/if}}

      </div>
    {{/if}}
  </template>
}
