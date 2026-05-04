import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { service } from "@ember/service";
import { on } from "@ember/modifier";
import { fn, concat } from "@ember/helper";
import { eq, not } from "truth-helpers";

export default class RcEventsList extends Component {
  @service currentUser;
  @tracked events = [];
  @tracked loading = true;
  @tracked isRcMeetings = false;
  @tracked filterOptions = { organisations: [], event_types: [], track_environments: [], track_surfaces: [] };
  @tracked viewMode = "list";
  @tracked currentYear = new Date().getFullYear();
  @tracked currentMonth = new Date().getMonth();
  @tracked popoverDayKey = null;
  @tracked popoverPosition = { top: 0, left: 0 };

  @tracked timeFilter = "default";
  @tracked organisationId = "";
  @tracked eventTypeId = "";
  @tracked trackEnvironment = "";
  @tracked trackSurface = "";
  @tracked scaleFilter = "";
  @tracked powerFilter = "";
  @tracked maxDistanceMiles = "";
  @tracked searchPostcode = "";
  @tracked postcodeInput = "";
  @tracked postcodeError = "";
  @tracked userPostcode = "";

  constructor() {
    super(...arguments);
    this.checkCategory();
  }

  async checkCategory() {
    const category = this.args.outletArgs?.category;
    if (!category || category.name !== "RC Meetings") {
      this.isRcMeetings = false;
      this.loading = false;
      return;
    }
    this.isRcMeetings = true;
    try {
      const response = await ajax("/des/racing-profile.json");
      this.userPostcode = response?.user?.des_postcode || "";
      this.searchPostcode = this.userPostcode;
      this.postcodeInput = this.userPostcode;
    } catch {
      // not logged in or no profile
    }
    await this.loadEvents();
  }

  async loadEvents() {
    this.loading = true;
    try {
      const params = {};
      if (this.viewMode === "calendar") {
        params.time_filter = "all";
      } else {
        if (this.timeFilter !== "default") params.time_filter = this.timeFilter;
      }
      if (this.organisationId) params.organisation_id = this.organisationId;
      if (this.eventTypeId) params.event_type_id = this.eventTypeId;
      if (this.trackEnvironment) params.track_environment = this.trackEnvironment;
      if (this.trackSurface) params.track_surface = this.trackSurface;
      if (this.scaleFilter) params.scale = this.scaleFilter;
      if (this.powerFilter) params.power_type = this.powerFilter;
      if (this.maxDistanceMiles && this.searchPostcode) {
        params.max_distance_miles = this.maxDistanceMiles;
        params.postcode = this.searchPostcode;
      }

      const response = await ajax("/des/rc-events-topic-list.json", { data: params });
      const native = response.topics || [];
      const imported = (response.imported_events || []).map(e => ({
        ...e,
        // Normalize date fields for calendar compatibility
        _startDate: e.start_date,
      }));
      // Merge and sort by start date
      const merged = [...native, ...imported].sort((a, b) => {
        const dateA = new Date(a.start_date);
        const dateB = new Date(b.start_date);
        return dateA - dateB;
      });
      this.events = merged;
      if (response.filters) this.filterOptions = response.filters;
    } catch {
      this.events = [];
    } finally {
      this.loading = false;
    }
  }

  @action async updateTimeFilter(e) { this.timeFilter = e.target.value; await this.loadEvents(); }
  @action async updateOrganisation(e) { this.organisationId = e.target.value; await this.loadEvents(); }
  @action async updateEventType(e) { this.eventTypeId = e.target.value; await this.loadEvents(); }
  @action async updateEnvironment(e) { this.trackEnvironment = e.target.value; await this.loadEvents(); }
  @action async updateSurface(e) { this.trackSurface = e.target.value; await this.loadEvents(); }
  @action async updateScale(e) { this.scaleFilter = e.target.value; await this.loadEvents(); }
  @action async updatePower(e) { this.powerFilter = e.target.value; await this.loadEvents(); }

  @action
  updatePostcodeInput(e) {
    this.postcodeInput = e.target.value;
    this.postcodeError = "";
  }

  @action
  async updateDistance(e) {
    this.maxDistanceMiles = e.target.value;
    if (e.target.value && this.searchPostcode) {
      await this.loadEvents();
    } else if (!e.target.value) {
      await this.loadEvents();
    }
  }

  @action
  async applyPostcode() {
    if (!this.postcodeInput.trim()) {
      this.postcodeError = "Please enter a postcode";
      return;
    }
    try {
      const response = await ajax("/des/geocode-postcode.json", {
        data: { postcode: this.postcodeInput.trim() }
      });
      if (response.success) {
        this.searchPostcode = this.postcodeInput.trim();
        this.postcodeError = "";
        await this.loadEvents();
      } else {
        this.postcodeError = "Invalid postcode";
      }
    } catch {
      this.postcodeError = "Invalid postcode";
    }
  }

  @action
  async toggleBookingAlert(event, e) {
    e.preventDefault();
    e.stopPropagation();
    if (!this.currentUser) return;
    try {
      if (event.user_has_booking_alert) {
        await ajax(`/des/events/${event.id}/booking-alert.json`, { type: "DELETE" });
      } else {
        await ajax(`/des/events/${event.id}/booking-alert.json`, { type: "POST" });
      }
      await this.loadEvents();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  async setView(mode) {
    this.viewMode = mode;
    this.popoverDayKey = null;
    await this.loadEvents();
  }

  @action
  prevMonth() {
    if (this.currentMonth === 0) {
      this.currentMonth = 11;
      this.currentYear = this.currentYear - 1;
    } else {
      this.currentMonth = this.currentMonth - 1;
    }
    this.popoverDayKey = null;
  }

  @action
  nextMonth() {
    if (this.currentMonth === 11) {
      this.currentMonth = 0;
      this.currentYear = this.currentYear + 1;
    } else {
      this.currentMonth = this.currentMonth + 1;
    }
    this.popoverDayKey = null;
  }

  @action
  togglePopover(dayKey, e) {
    if (this.popoverDayKey === dayKey) {
      this.popoverDayKey = null;
      return;
    }
    const rect = e.currentTarget.getBoundingClientRect();
    const viewportHeight = window.innerHeight;
    const popoverHeight = 300;

    let top = rect.bottom + 4;
    if (top + popoverHeight > viewportHeight) {
      top = rect.top - popoverHeight - 4;
    }

    let left = rect.left;
    if (left + 300 > window.innerWidth) {
      left = window.innerWidth - 310;
    }

    this.popoverPosition = { top, left };
    this.popoverDayKey = dayKey;
  }

  @action
  closePopover() {
    this.popoverDayKey = null;
  }

  get currentMonthName() {
    return new Date(this.currentYear, this.currentMonth, 1)
      .toLocaleDateString("en-GB", { month: "long", year: "numeric" });
  }

  get calendarDays() {
    const year = this.currentYear;
    const month = this.currentMonth;
    const firstDay = new Date(year, month, 1);
    const lastDay = new Date(year, month + 1, 0);

    let startDow = firstDay.getDay();
    startDow = startDow === 0 ? 6 : startDow - 1;

    const days = [];

    for (let i = 0; i < startDow; i++) {
      days.push({ date: null, key: `pad-start-${i}` });
    }

    for (let d = 1; d <= lastDay.getDate(); d++) {
      const date = new Date(year, month, d);
      const key = `${year}-${String(month + 1).padStart(2, '0')}-${String(d).padStart(2, '0')}`;
      const dayEvents = this.eventsForDay(date);
      days.push({ date, day: d, key, dayEvents, isToday: this.isToday(date) });
    }

    const remaining = (7 - (days.length % 7)) % 7;
    for (let i = 0; i < remaining; i++) {
      days.push({ date: null, key: `pad-end-${i}` });
    }

    return days;
  }

  eventsForDay(date) {
    return this.events.filter(event => {
      const start = new Date(event.start_date);
      const end = event.end_date ? new Date(event.end_date) : start;
      const startDate = new Date(start.getFullYear(), start.getMonth(), start.getDate());
      const endDate = new Date(end.getFullYear(), end.getMonth(), end.getDate());
      const checkDate = new Date(date.getFullYear(), date.getMonth(), date.getDate());
      return checkDate >= startDate && checkDate <= endDate;
    });
  }

  isToday(date) {
    const today = new Date();
    return date.getFullYear() === today.getFullYear() &&
           date.getMonth() === today.getMonth() &&
           date.getDate() === today.getDate();
  }

  eventBadgeClass(event) {
    if (event.type === 'imported') return "rc-cal-event--imported";
    if (event.is_past) return "rc-cal-event--past";
    if (event.booking_manually_closed) return "rc-cal-event--closed";
    if (event.booking_open) return "rc-cal-event--open";
    if (event.booking_opens_at) return "rc-cal-event--soon";
    return "rc-cal-event--closed";
  }

  eventUrl(event) {
    if (event.type === 'imported') return event.booking_url;
    return event.topic_url;
  }

  isImported(event) {
    return event.type === 'imported';
  }

  <template>
    {{#if this.isRcMeetings}}
      <div class="rc-events-list">

        <div class="rc-view-toggle">
          <button class="btn btn-small {{if (eq this.viewMode 'list') 'btn-primary' 'btn-default'}}" {{on "click" (fn this.setView "list")}}>☰ List</button>
          <button class="btn btn-small {{if (eq this.viewMode 'calendar') 'btn-primary' 'btn-default'}}" {{on "click" (fn this.setView "calendar")}}>📅 Calendar</button>
        </div>

        <div class="rc-events-filters">
          {{#if (eq this.viewMode "list")}}
            <div class="rc-filter-group">
              <select class="rc-filter-select" {{on "change" this.updateTimeFilter}}>
                <option value="default" selected={{eq this.timeFilter "default"}}>📅 Upcoming & Today</option>
                <option value="today" selected={{eq this.timeFilter "today"}}>📍 Today</option>
                <option value="upcoming" selected={{eq this.timeFilter "upcoming"}}>⏭ Upcoming</option>
                <option value="past" selected={{eq this.timeFilter "past"}}>✅ Past</option>
              </select>
            </div>
          {{/if}}

          {{#if this.filterOptions.organisations.length}}
            <div class="rc-filter-group">
              <select class="rc-filter-select" {{on "change" this.updateOrganisation}}>
                <option value="">All Organisations</option>
                {{#each this.filterOptions.organisations as |org|}}
                  <option value={{org.id}} selected={{eq this.organisationId (concat "" org.id)}}>{{org.name}}</option>
                {{/each}}
              </select>
            </div>
          {{/if}}

          {{#if this.filterOptions.event_types.length}}
            <div class="rc-filter-group">
              <select class="rc-filter-select" {{on "change" this.updateEventType}}>
                <option value="">All Event Types</option>
                {{#each this.filterOptions.event_types as |et|}}
                  <option value={{et.id}} selected={{eq this.eventTypeId (concat "" et.id)}}>{{et.name}}</option>
                {{/each}}
              </select>
            </div>
          {{/if}}

          {{#if this.filterOptions.track_environments.length}}
            <div class="rc-filter-group">
              <select class="rc-filter-select" {{on "change" this.updateEnvironment}}>
                <option value="">All Environments</option>
                <option value="outdoor" selected={{eq this.trackEnvironment "outdoor"}}>🌳 Outdoor</option>
                <option value="indoor_covered" selected={{eq this.trackEnvironment "indoor_covered"}}>🏠 Indoor</option>
              </select>
            </div>
          {{/if}}

          {{#if this.filterOptions.track_surfaces.length}}
            <div class="rc-filter-group">
              <select class="rc-filter-select" {{on "change" this.updateSurface}}>
                <option value="">All Surfaces</option>
                {{#each this.filterOptions.track_surfaces as |surface|}}
                  <option value={{surface}} selected={{eq this.trackSurface surface}}>{{surface}}</option>
                {{/each}}
              </select>
            </div>
          {{/if}}

          <div class="rc-filter-group">
            <select class="rc-filter-select" {{on "change" this.updateScale}}>
              <option value="">All scales</option>
              <option value="1/10" selected={{eq this.scaleFilter "1/10"}}>1/10</option>
              <option value="1/8" selected={{eq this.scaleFilter "1/8"}}>1/8</option>
              <option value="1/12" selected={{eq this.scaleFilter "1/12"}}>1/12</option>
              <option value="large_scale" selected={{eq this.scaleFilter "large_scale"}}>Large Scale</option>
            </select>
          </div>

          <div class="rc-filter-group">
            <select class="rc-filter-select" {{on "change" this.updatePower}}>
              <option value="">All power</option>
              <option value="electric" selected={{eq this.powerFilter "electric"}}>⚡ Electric</option>
              <option value="nitro" selected={{eq this.powerFilter "nitro"}}>🔥 Nitro</option>
              <option value="petrol" selected={{eq this.powerFilter "petrol"}}>⛽ Petrol</option>
              <option value="mixed" selected={{eq this.powerFilter "mixed"}}>Mixed</option>
            </select>
          </div>

          <div class="rc-filter-group">
            <select class="rc-filter-select" {{on "change" this.updateDistance}}>
              <option value="">Any distance</option>
              <option value="5" selected={{eq this.maxDistanceMiles "5"}}>Within 5 miles</option>
              <option value="10" selected={{eq this.maxDistanceMiles "10"}}>Within 10 miles</option>
              <option value="15" selected={{eq this.maxDistanceMiles "15"}}>Within 15 miles</option>
              <option value="25" selected={{eq this.maxDistanceMiles "25"}}>Within 25 miles</option>
              <option value="50" selected={{eq this.maxDistanceMiles "50"}}>Within 50 miles</option>
              <option value="75" selected={{eq this.maxDistanceMiles "75"}}>Within 75 miles</option>
              <option value="100" selected={{eq this.maxDistanceMiles "100"}}>Within 100 miles</option>
            </select>
          </div>

          {{#if this.maxDistanceMiles}}
            <div class="rc-filter-group rc-postcode-group">
              <div style="display:flex;gap:4px;align-items:center;">
                <input
                  type="text"
                  class="rc-filter-select"
                  placeholder="Enter postcode..."
                  value={{this.postcodeInput}}
                  {{on "input" this.updatePostcodeInput}}
                  style="flex:1;"
                />
                <button class="btn btn-small btn-primary" {{on "click" this.applyPostcode}}>📍</button>
              </div>
              {{#if this.postcodeError}}
                <p class="field-help" style="color:var(--danger);margin:2px 0 0;">{{this.postcodeError}}</p>
              {{else if this.searchPostcode}}
                <p class="field-help" style="margin:2px 0 0;">📍 From: {{this.searchPostcode}}</p>
              {{/if}}
            </div>
          {{/if}}
        </div>

        {{#if this.loading}}
          <div class="rc-events-loading">Loading events...</div>

        {{else if (eq this.viewMode "list")}}
          {{#if this.events.length}}
            <div class="rc-events-cards">
              {{#each this.events as |event|}}
                {{#if (eq event.type "imported")}}
                  <div class="rc-event-card rc-event-card--imported {{if event.is_past 'rc-event-card--past' ''}} {{if event.is_today 'rc-event-card--today' ''}}">
                    <div class="rc-card-header">
                      <div class="rc-card-title-block">
                        <h3 class="rc-event-title">{{event.title}}</h3>
                        <div class="rc-card-date">📅 {{event.formatted_date}}</div>
                      </div>
                      <div class="rc-card-status-badges">
                        <span class="rc-event-badge rc-event-badge--brca">BRCA</span>
                        {{#if event.series_type}}
                          <span class="rc-event-badge rc-event-badge--series">{{event.series_type}}</span>
                        {{/if}}
                        {{#if event.region}}
                          <span class="rc-event-badge rc-event-badge--region">{{event.region}}</span>
                        {{/if}}
                        {{#if event.is_today}}
                          <span class="rc-event-badge rc-event-badge--today">📍 Today</span>
                        {{else if event.is_past}}
                          <span class="rc-event-badge rc-event-badge--past">✅ Past</span>
                        {{/if}}
                      </div>
                    </div>

                    <div class="rc-card-body">
                      <div class="rc-card-org">
                        <div class="rc-org-logo-placeholder">🏁</div>
                        <span class="rc-event-org-name">{{event.organisation.name}}</span>
                      </div>

                      <div class="rc-card-venue">
                        {{#if event.venue}}
                          <div class="rc-venue-name">📍 {{event.venue.name}}</div>
                        {{else}}
                          <div class="rc-venue-name rc-venue-none">📍 Venue TBC</div>
                        {{/if}}
                        {{#if event.round_number}}
                          <div class="rc-venue-distance">Round {{event.round_number}}</div>
                        {{/if}}
                      </div>
                    </div>

                    <div class="rc-card-footer">
                      <div class="rc-card-classes">
                        {{#if event.scale}}
                          <span class="rc-event-class-tag rc-event-tag--scale">{{event.scale}}</span>
                        {{/if}}
                        {{#if event.power_type}}
                          <span class="rc-event-class-tag rc-event-tag--power rc-event-tag--{{event.power_type}}">
                            {{#if (eq event.power_type "electric")}}⚡{{else if (eq event.power_type "nitro")}}🔥{{else if (eq event.power_type "petrol")}}⛽{{else}}🔄{{/if}}
                            {{event.power_type}}
                          </span>
                        {{/if}}
                        {{#if event.surface}}
                          <span class="rc-event-class-tag rc-event-tag--surface">
                            {{#if (eq event.surface "off_road")}}🏔️ Off Road{{else}}🏁 On Road{{/if}}
                          </span>
                        {{/if}}
                        {{#each event.classes_raw as |cls|}}
                          <span class="rc-event-class-tag">{{cls}}</span>
                        {{/each}}
                      </div>
                      <div class="rc-card-booking">
                        <a href={{event.booking_url}} target="_blank" rel="noopener" class="btn btn-small btn-default">
                          Book on BRCA →
                        </a>
                      </div>
                    </div>
                  </div>

                {{else}}
                  <a href={{event.topic_url}} class="rc-event-card {{if event.is_past 'rc-event-card--past' ''}} {{if event.is_today 'rc-event-card--today' ''}}">

                    <div class="rc-card-header">
                      <div class="rc-card-title-block">
                        <h3 class="rc-event-title">{{event.title}}</h3>
                        <div class="rc-card-date">📅 {{event.formatted_date}}</div>
                      </div>
                      <div class="rc-card-status-badges">
                        {{#if event.is_today}}
                          <span class="rc-event-badge rc-event-badge--today">📍 Today</span>
                        {{else if event.is_past}}
                          <span class="rc-event-badge rc-event-badge--past">✅ Past</span>
                        {{/if}}
                      </div>
                    </div>

                    <div class="rc-card-body">
                      <div class="rc-card-org">
                        {{#if event.organisation.logo_url}}
                          <img src={{event.organisation.logo_url}} alt={{event.organisation.name}} class="rc-event-org-logo" />
                        {{else}}
                          <div class="rc-org-logo-placeholder">🏭</div>
                        {{/if}}
                        <span class="rc-event-org-name">{{event.organisation.name}}</span>
                      </div>

                      <div class="rc-card-venue">
                        {{#if event.venue}}
                          <div class="rc-venue-name">{{event.venue.name}}</div>
                          <div class="rc-venue-attrs">
                            {{#each event.venue.tracks as |track|}}
                              {{#if track.environment}}
                                <span class="rc-icon-badge" title={{track.environment}}>{{#if (eq track.environment "outdoor")}}🌳{{else}}🏠{{/if}}</span>
                              {{/if}}
                              {{#if track.surface}}
                                <span class="rc-icon-badge" title={{track.surface}}>
                                  {{#if (eq track.surface "carpet")}}🟫
                                  {{else if (eq track.surface "astroturf")}}🌿
                                  {{else if (eq track.surface "grass")}}🍃
                                  {{else if (eq track.surface "tarmac")}}⬛
                                  {{else if (eq track.surface "mixed")}}🔀
                                  {{else}}🏁{{/if}}
                                </span>
                              {{/if}}
                            {{/each}}
                            {{#if event.venue.has_permanent_toilets}}<span class="rc-icon-badge" title="Permanent Toilets">🚻</span>{{/if}}
                            {{#if event.venue.has_portaloos}}<span class="rc-icon-badge" title="Portaloos">🚽</span>{{/if}}
                            {{#if event.venue.has_cafe}}<span class="rc-icon-badge" title="Café">☕</span>{{/if}}
                            {{#if event.venue.has_bar}}<span class="rc-icon-badge" title="Bar">🍺</span>{{/if}}
                            {{#if event.venue.has_showers}}<span class="rc-icon-badge" title="Showers">🚿</span>{{/if}}
                            {{#if event.venue.has_power_supply}}<span class="rc-icon-badge" title="Power Supply">⚡</span>{{/if}}
                            {{#if event.venue.has_water_supply}}<span class="rc-icon-badge" title="Water Supply">💧</span>{{/if}}
                            {{#if event.venue.has_camping}}<span class="rc-icon-badge" title="Camping">⛺</span>{{/if}}
                            {{#if event.venue.has_track_shop}}<span class="rc-icon-badge" title="Track Shop">🛒</span>{{/if}}
                          </div>
                          {{#if event.distance_miles}}
                            <div class="rc-venue-distance" title="Distance from your postcode">📏 {{event.distance_miles}} miles</div>
                          {{/if}}
                        {{else}}
                          <div class="rc-venue-name rc-venue-none">📍 Venue TBC</div>
                        {{/if}}
                      </div>
                    </div>

                    <div class="rc-card-footer">
                      <div class="rc-card-classes">
                        {{#each event.classes as |cls|}}
                          <span class="rc-event-class-tag">{{cls}}</span>
                        {{/each}}
                      </div>
                      <div class="rc-card-booking">
                        {{#if event.booking_manually_closed}}
                          <span class="rc-event-badge rc-event-badge--closed">🔴 Booking Closed</span>
                        {{else if event.booking_open}}
                          <span class="rc-event-badge rc-event-badge--open">🟢 Booking Open</span>
                        {{else if event.booking_opens_at}}
                          <span class="rc-event-badge rc-event-badge--soon">⏳ Booking Soon</span>
                          {{#if this.currentUser}}
                            <button
                              class="btn btn-small btn-default rc-alert-btn"
                              {{on "click" (fn this.toggleBookingAlert event)}}
                              title={{if event.user_has_booking_alert "Cancel booking alert" "Alert me when booking opens"}}
                            >
                              {{if event.user_has_booking_alert "🔕 Cancel Alert" "🔔 Alert Me"}}
                            </button>
                          {{/if}}
                        {{else}}
                          <span class="rc-event-badge rc-event-badge--closed">🔴 Booking Closed</span>
                        {{/if}}
                      </div>
                    </div>

                  </a>
                {{/if}}
              {{/each}}
            </div>
          {{else}}
            <div class="rc-events-empty">No events found for the selected filters.</div>
          {{/if}}

        {{else}}
          <div class="rc-calendar">
            <div class="rc-calendar-header">
              <button class="btn btn-default btn-small" {{on "click" this.prevMonth}}>← Prev</button>
              <h3 class="rc-calendar-month">{{this.currentMonthName}}</h3>
              <button class="btn btn-default btn-small" {{on "click" this.nextMonth}}>Next →</button>
            </div>

            <div class="rc-calendar-grid">
              <div class="rc-cal-day-header">Mon</div>
              <div class="rc-cal-day-header">Tue</div>
              <div class="rc-cal-day-header">Wed</div>
              <div class="rc-cal-day-header">Thu</div>
              <div class="rc-cal-day-header">Fri</div>
              <div class="rc-cal-day-header">Sat</div>
              <div class="rc-cal-day-header">Sun</div>

              {{#each this.calendarDays as |day|}}
                {{#if day.date}}
                  <div class="rc-cal-cell {{if day.isToday 'rc-cal-cell--today' ''}}">
                    <div class="rc-cal-date">{{day.day}}</div>

                    {{#if day.dayEvents.length}}
                      {{#if (eq day.dayEvents.length 1)}}
                        <a href={{if (eq day.dayEvents.[0].type "imported") day.dayEvents.[0].booking_url day.dayEvents.[0].topic_url}} class="rc-cal-event {{this.eventBadgeClass day.dayEvents.[0]}}" target={{if (eq day.dayEvents.[0].type "imported") "_blank" ""}} rel={{if (eq day.dayEvents.[0].type "imported") "noopener" ""}}>
                          {{day.dayEvents.[0].title}}
                        </a>
                      {{else}}
                        <button class="rc-cal-multi-badge" {{on "click" (fn this.togglePopover day.key)}}>
                          {{day.dayEvents.length}} events
                        </button>
                      {{/if}}
                    {{/if}}
                  </div>
                {{else}}
                  <div class="rc-cal-cell rc-cal-cell--empty"></div>
                {{/if}}
              {{/each}}
            </div>

            {{#if this.popoverDayKey}}
              {{#each this.calendarDays as |day|}}
                {{#if (eq day.key this.popoverDayKey)}}
                  <div class="rc-cal-popover" style="top: {{this.popoverPosition.top}}px; left: {{this.popoverPosition.left}}px;">
                    <button class="rc-cal-popover-close" {{on "click" this.closePopover}}>✕</button>
                    {{#each day.dayEvents as |event|}}
                      <a href={{if (eq event.type "imported") event.booking_url event.topic_url}} class="rc-cal-popover-event {{this.eventBadgeClass event}}" target={{if (eq event.type "imported") "_blank" ""}} rel={{if (eq event.type "imported") "noopener" ""}}>
                        <span class="rc-cal-popover-title">{{event.title}}</span>
                        <span class="rc-cal-popover-org">{{event.organisation.name}}</span>
                      </a>
                    {{/each}}
                  </div>
                {{/if}}
              {{/each}}
            {{/if}}
          </div>
        {{/if}}

      </div>
    {{/if}}
  </template>
}
