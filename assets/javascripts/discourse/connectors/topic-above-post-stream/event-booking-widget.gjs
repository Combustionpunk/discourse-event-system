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
  @tracked showTransponderConfirm = false;
  @tracked transponderConfirmations = {};
  @tracked userTransponders = [];
  @tracked transponderSelections = {};

  constructor() {
    super(...arguments);
    this.loadEvent();
  }

  async loadUserTransponders() {
    try {
      const response = await ajax("/des/transponders.json");
      this.userTransponders = response.transponders;
    } catch {
      this.userTransponders = [];
    }
  }

  transponderLabel(longCode) {
    if (!longCode) return "None";
    const t = this.userTransponders.find(tr => tr.long_code === longCode);
    return t ? `#${t.shortcode} — ${longCode}` : longCode;
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
      if (ids.length > 0) {
        const member = (this.event.family_members || []).find(m => String(m.user_id) === String(uid));
        total += this._calcForClasses(ids.length, isMember, member?.is_junior || false);
      }
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

  totalSelectionsForClass(classId) {
    let count = this.selectedClasses.includes(classId) ? 1 : 0;
    Object.values(this.familySelections).forEach(ids => {
      if (ids && ids.includes(classId)) count++;
    });
    return count;
  }

  classHasSpace(classId) {
    const cls = (this.event?.classes || []).find(c => c.id === classId);
    if (!cls) return false;
    return this.totalSelectionsForClass(classId) < cls.spaces_remaining;
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


  get refundPeriodEnded() {
    if (!this.event?.refund_cutoff_days || !this.event?.start_date) return false;
    const cutoff = new Date(new Date(this.event.start_date).getTime() - this.event.refund_cutoff_days * 86400000);
    return new Date() > cutoff;
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
      if (!this.classHasSpace(classId)) { alert("No spaces remaining in this class for additional racers."); return; }
      this.selectedClasses = [...this.selectedClasses, classId];
    }
  }

  @action toggleFamilySection() { this.familyExpanded = !this.familyExpanded; }

  @action toggleFamilyClass(userId, classId) {
    const c = { ...this.familySelections };
    const uc = c[userId] || [];
    if (uc.includes(classId)) {
      c[userId] = uc.filter(id => id !== classId);
    } else {
      if (!this.classHasSpace(classId)) { alert("No spaces remaining in this class for additional racers."); return; }
      c[userId] = [...uc, classId];
    }
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
      await this.loadUserTransponders();
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
    this.showCarSelection = false;
    this.showTransponderConfirm = false;
    this.eligibleCars = [];
    this.carSelections = {};
    this.transponderConfirmations = {};
    this.transponderSelections = {};
    this.familyEligibleCars = null;
    this.familyCarSelections = {};
  }

  @action
  proceedToTransponderConfirm() {
    const confirmations = {};

    for (const [classId, carId] of Object.entries(this.carSelections)) {
      const cls = this.eligibleCars.find(c => c.class_id === parseInt(classId));
      const car = cls?.eligible_cars.find(c => c.id === parseInt(carId));
      if (car) {
        confirmations[carId] = { car, classId, status: 'pending', isFamily: false };
      }
    }

    if (this.familyEligibleCars) {
      for (const entry of this.familyEligibleCars) {
        for (const cls of entry.classes) {
          const key = `${entry.user_id}_${cls.class_id}`;
          const carId = this.familyCarSelections[key];
          if (carId) {
            const car = cls.eligible_cars.find(c => c.id === parseInt(carId));
            if (car) {
              confirmations[`family_${entry.user_id}_${carId}`] = {
                car, classId: cls.class_id, userId: entry.user_id,
                username: entry.username, status: 'pending', isFamily: true
              };
            }
          }
        }
      }
    }

    this.transponderConfirmations = confirmations;
    this.showTransponderConfirm = true;
    this.showCarSelection = false;
  }

  @action
  confirmTransponder(key) {
    this.transponderConfirmations = {
      ...this.transponderConfirmations,
      [key]: { ...this.transponderConfirmations[key], status: 'confirmed' }
    };
  }

  @action
  changeTransponder(key) {
    this.transponderConfirmations = {
      ...this.transponderConfirmations,
      [key]: { ...this.transponderConfirmations[key], status: 'changing' }
    };
  }

  @action
  selectNewTransponder(key, carId, event) {
    const value = event.target.value;
    if (!value) return;
    const transponder = this.userTransponders.find(t => t.id === parseInt(value));
    if (transponder) {
      this.transponderSelections = { ...this.transponderSelections, [key]: transponder.long_code };
      this.transponderConfirmations = {
        ...this.transponderConfirmations,
        [key]: { ...this.transponderConfirmations[key], status: 'confirmed', newTransponder: transponder }
      };
    }
  }

  get allTranspondersConfirmed() {
    return Object.values(this.transponderConfirmations).every(c => c.status === 'confirmed');
  }

  @action async confirmBooking() {
    this.isBooking = true;
    try {
      // Save any changed transponders back to car records
      for (const [, confirmation] of Object.entries(this.transponderConfirmations)) {
        if (confirmation.status === 'confirmed' && confirmation.newTransponder) {
          try {
            await ajax(`/des/garage/${confirmation.car.id}.json`, {
              type: "PUT",
              data: { car: { transponder_number: confirmation.newTransponder.long_code } }
            });
          } catch { /* continue with booking even if transponder update fails */ }
        }
      }
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
            {{#if this.event.organisation.logo_url}}<img src={{this.event.organisation.logo_url}} class="org-logo org-logo--inline" alt="" />{{/if}} <strong>Organisation:</strong> {{this.event.organisation.name}}
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
          {{#if this.event.venue}}
            <div class="event-venue-card event-venue-card--compact">
              <strong><a href="/venues/{{this.event.venue.id}}">{{this.event.venue.name}}</a></strong>
              {{#if this.event.venue.address}}<div class="venue-detail-item">📍 {{this.event.venue.address}}</div>{{/if}}
              {{#if this.event.venue.google_maps_url}}<div class="venue-detail-item"><a href={{this.event.venue.google_maps_url}} target="_blank" rel="noopener">🗺️ Map</a></div>{{/if}}
              <div class="venue-badges">
                {{#if this.event.venue.track_environment}}<span class="venue-badge venue-badge--environment">{{#if (eq this.event.venue.track_environment "outdoor")}}🌳 Outdoor{{else}}🏠 Indoor{{/if}}</span>{{/if}}
                {{#if this.event.venue.track_category}}<span class="venue-badge venue-badge--category">{{#if (eq this.event.venue.track_category "onroad")}}🛣️ On-Road{{else}}🌿 Off-Road{{/if}}</span>{{/if}}
                {{#if this.event.venue.track_surface}}<span class="venue-badge venue-badge--surface">{{this.event.venue.track_surface}}</span>{{/if}}
              </div>
              <div class="venue-facilities-icons">
                {{#if this.event.venue.has_permanent_toilets}}🚻{{/if}}
                {{#if this.event.venue.has_portaloos}}🚽{{/if}}
                {{#if this.event.venue.has_bar}}🍺{{/if}}
                {{#if this.event.venue.has_showers}}🚿{{/if}}
                {{#if this.event.venue.has_power_supply}}⚡{{/if}}
                {{#if this.event.venue.has_water_supply}}💧{{/if}}
                {{#if this.event.venue.has_camping}}⛺{{/if}}
              </div>
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
                  {{#if cls.user_waitlist_position}}
                    <div class="waitlist-status">📋 Position #{{cls.user_waitlist_position}}</div>
                  {{else}}
                    <button class="btn btn-small btn-default" {{on "click" (fn this.joinWaitlist cls.id)}}>📋 Join Waitlist</button>
                  {{/if}}
                  {{#if cls.waitlist_count}}<span class="waitlist-count">{{cls.waitlist_count}} waiting</span>{{/if}}
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


          <div class="event-booking-dates">
            {{#if this.event.booking_closing_date}}
              <p class="booking-date-info {{if this.bookingClosed 'booking-closed'}}">
                {{#if this.bookingClosed}}
                  ⚠️ Booking is now closed
                {{else}}
                  📅 Booking closes: {{this.event.formatted_booking_closing_date}}
                {{/if}}
              </p>
            {{/if}}
            {{#if this.event.refund_cutoff_days}}
              <p class="refund-info {{if this.refundPeriodEnded 'refund-ended'}}">
                {{#if this.refundPeriodEnded}}
                  ⚠️ Refund period has ended
                {{else}}
                  💰 Refund available until: {{this.event.refund_cutoff_date}}
                {{/if}}
              </p>
            {{else}}
              <p class="refund-info refund-ended">💰 No refunds available</p>
            {{/if}}
          </div>
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
                <button class="btn btn-small {{if (eq this.entrantsFilter 'waitlist') 'btn-primary' 'btn-default'}}" {{on "click" (fn this.setEntrantsFilter "waitlist")}}>📋 Waitlist ({{this.entrantsStatusCounts.waitlist}})</button>
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
                          <th>Full Name</th>
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
                            <td>{{entrant.name}}</td>
                            <td>{{entrant.manufacturer_name}}</td>
                            <td>{{entrant.model_name}}</td>
                            <td class="transponder-number">{{entrant.transponder}}</td>
                            <td>{{entrant.brca_number}}</td>
                            <td><span class="booking-status booking-status--{{entrant.status}}">{{#if entrant.waitlist_position}}Waitlist #{{entrant.waitlist_position}}{{else}}{{entrant.status}}{{/if}}</span></td>
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
                        <option value={{car.id}}>{{car.friendly_name}} — {{car.driveline}} — {{car.transponder_number}}{{#if car.owner_username}} ({{car.owner_username}}){{/if}}{{#if (eq car.model_status "pending")}} ⚠️ pending{{/if}}</option>
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
                            <option value={{car.id}}>{{car.friendly_name}} — {{car.driveline}} — {{car.transponder_number}}{{#if car.owner_username}} ({{car.owner_username}}){{/if}}{{#if (eq car.model_status "pending")}} ⚠️ pending{{/if}}</option>
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
                <button class="btn btn-primary" disabled={{not this.allCarsSelected}} {{on "click" this.proceedToTransponderConfirm}}>Next: Confirm Transponders →</button>
                <button class="btn btn-default" {{on "click" this.cancelCarSelection}}>Cancel</button>
              </div>
            </div>
          </div>
        {{/if}}

        {{!-- Transponder Confirmation Modal --}}
        {{#if this.showTransponderConfirm}}
          <div class="car-selection-overlay">
            <div class="car-selection-modal">
              <h2>📡 Confirm Transponders</h2>
              <p class="field-help">Please confirm the transponder for each car before booking.</p>

              {{#each-in this.transponderConfirmations as |key confirmation|}}
                <div class="transponder-confirm-card" style="background: var(--primary-very-low); border: 1px solid var(--primary-low); border-radius: 6px; padding: 12px 16px; margin-bottom: 8px;">
                  <h4 style="margin: 0 0 8px;">{{confirmation.car.friendly_name}}{{#if confirmation.isFamily}} <span class="field-help">({{confirmation.username}})</span>{{/if}}</h4>

                  {{#if (eq confirmation.status "confirmed")}}
                    <div style="display:flex;align-items:center;gap:8px;">
                      <span>✅ {{#if confirmation.newTransponder}}#{{confirmation.newTransponder.shortcode}} — {{confirmation.newTransponder.long_code}}{{else}}{{confirmation.car.transponder_number}}{{/if}}</span>
                      <button class="btn btn-small btn-default" {{on "click" (fn this.changeTransponder key)}}>Change</button>
                    </div>
                  {{else if (eq confirmation.status "changing")}}
                    <select {{on "change" (fn this.selectNewTransponder key confirmation.car.id)}}>
                      <option value="">Select transponder...</option>
                      {{#each this.userTransponders as |t|}}
                        <option value={{t.id}}>#{{t.shortcode}} — {{t.long_code}}{{#if t.notes}} ({{t.notes}}){{/if}}</option>
                      {{/each}}
                    </select>
                  {{else}}
                    {{#if confirmation.car.transponder_number}}
                      <p style="margin: 0 0 8px;">Current transponder: <strong>{{confirmation.car.transponder_number}}</strong></p>
                      <div style="display:flex;gap:8px;">
                        <button class="btn btn-primary btn-small" {{on "click" (fn this.confirmTransponder key)}}>✅ Yes, correct</button>
                        <button class="btn btn-default btn-small" {{on "click" (fn this.changeTransponder key)}}>🔄 Change</button>
                      </div>
                    {{else}}
                      <p class="field-help" style="margin: 0 0 8px;">⚠️ No transponder set. Please select one:</p>
                      <select {{on "change" (fn this.selectNewTransponder key confirmation.car.id)}}>
                        <option value="">Select transponder...</option>
                        {{#each this.userTransponders as |t|}}
                          <option value={{t.id}}>#{{t.shortcode}} — {{t.long_code}}{{#if t.notes}} ({{t.notes}}){{/if}}</option>
                        {{/each}}
                      </select>
                    {{/if}}
                  {{/if}}
                </div>
              {{/each-in}}

              <div class="car-selection-actions" style="margin-top:16px;">
                <button class="btn btn-primary" disabled={{not this.allTranspondersConfirmed}} {{on "click" this.confirmBooking}}>
                  {{if this.isBooking "Processing..." "Confirm & Pay"}}
                </button>
                <button class="btn btn-default" {{on "click" this.cancelCarSelection}}>Cancel</button>
              </div>
            </div>
          </div>
        {{/if}}

      </div>
    {{/if}}
  </template>
}
