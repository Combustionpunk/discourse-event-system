import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { on } from "@ember/modifier";
import { fn, concat } from "@ember/helper";
import { eq } from "truth-helpers";

export default class RcEventsList extends Component {
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

      const response = await ajax("/des/rc-events-topic-list.json", { data: params });
      this.events = response.topics || [];
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
    if (event.is_past) return "rc-cal-event--past";
    if (event.booking_manually_closed) return "rc-cal-event--closed";
    if (event.booking_open) return "rc-cal-event--open";
    if (event.booking_opens_at) return "rc-cal-event--soon";
    return "rc-cal-event--closed";
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
        </div>

        {{#if this.loading}}
          <div class="rc-events-loading">Loading events...</div>

        {{else if (eq this.viewMode "list")}}
          {{#if this.events.length}}
            <div class="rc-events-cards">
              {{#each this.events as |event|}}
                <a href={{event.topic_url}} class="rc-event-card {{if event.is_past 'rc-event-card--past' ''}} {{if event.is_today 'rc-event-card--today' ''}}">
                  <div class="rc-event-card-header">
                    <div class="rc-event-org">
                      {{#if event.organisation.logo_url}}
                        <img src={{event.organisation.logo_url}} alt={{event.organisation.name}} class="rc-event-org-logo" />
                      {{/if}}
                      <span class="rc-event-org-name">{{event.organisation.name}}</span>
                    </div>
                    <div class="rc-event-badges">
                      {{#if event.is_today}}
                        <span class="rc-event-badge rc-event-badge--today">📍 Today</span>
                      {{else if event.is_past}}
                        <span class="rc-event-badge rc-event-badge--past">✅ Past</span>
                      {{/if}}
                      {{#if event.booking_manually_closed}}
                        <span class="rc-event-badge rc-event-badge--closed">🔴 Booking Closed</span>
                      {{else if event.booking_open}}
                        <span class="rc-event-badge rc-event-badge--open">🟢 Booking Open</span>
                      {{else if event.booking_opens_at}}
                        <span class="rc-event-badge rc-event-badge--soon">⏳ Booking Soon</span>
                      {{else}}
                        <span class="rc-event-badge rc-event-badge--closed">🔴 Booking Closed</span>
                      {{/if}}
                    </div>
                  </div>
                  <div class="rc-event-card-body">
                    <h3 class="rc-event-title">{{event.title}}</h3>
                    <div class="rc-event-meta">
                      <span class="rc-event-date">📅 {{event.formatted_date}}</span>
                      {{#if event.venue}}
                        <span class="rc-event-venue">📍 {{event.venue.name}}</span>
                      {{/if}}
                    </div>
                    {{#if event.classes.length}}
                      <div class="rc-event-classes">
                        {{#each event.classes as |cls|}}
                          <span class="rc-event-class-tag">{{cls}}</span>
                        {{/each}}
                      </div>
                    {{/if}}
                  </div>
                </a>
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
                        <a href={{day.dayEvents.[0].topic_url}} class="rc-cal-event {{this.eventBadgeClass day.dayEvents.[0]}}">
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
                      <a href={{event.topic_url}} class="rc-cal-popover-event {{this.eventBadgeClass event}}">
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
