import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { concat } from "@ember/helper";
import { on } from "@ember/modifier";
import { eq } from "truth-helpers";

export default class RcEventsList extends Component {
  @tracked events = [];
  @tracked loading = true;
  @tracked isRcMeetings = false;
  @tracked filterOptions = { organisations: [], event_types: [], track_environments: [], track_surfaces: [] };

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
      if (this.timeFilter !== "default") params.time_filter = this.timeFilter;
      if (this.organisationId) params.organisation_id = this.organisationId;
      if (this.eventTypeId) params.event_type_id = this.eventTypeId;
      if (this.trackEnvironment) params.track_environment = this.trackEnvironment;
      if (this.trackSurface) params.track_surface = this.trackSurface;

      const response = await ajax("/des/rc-events-topic-list.json", { data: params });
      this.events = response.topics || [];
      if (response.filters) {
        this.filterOptions = response.filters;
      }
    } catch {
      this.events = [];
    } finally {
      this.loading = false;
    }
  }

  @action
  async updateTimeFilter(e) {
    this.timeFilter = e.target.value;
    await this.loadEvents();
  }

  @action
  async updateOrganisation(e) {
    this.organisationId = e.target.value;
    await this.loadEvents();
  }

  @action
  async updateEventType(e) {
    this.eventTypeId = e.target.value;
    await this.loadEvents();
  }

  @action
  async updateEnvironment(e) {
    this.trackEnvironment = e.target.value;
    await this.loadEvents();
  }

  @action
  async updateSurface(e) {
    this.trackSurface = e.target.value;
    await this.loadEvents();
  }

  <template>
    {{#if this.isRcMeetings}}
      <div class="rc-events-list">
        <div class="rc-events-filters">
          <div class="rc-filter-group">
            <select class="rc-filter-select" {{on "change" this.updateTimeFilter}}>
              <option value="default" selected={{eq this.timeFilter "default"}}>📅 Upcoming & Today</option>
              <option value="today" selected={{eq this.timeFilter "today"}}>📍 Today</option>
              <option value="upcoming" selected={{eq this.timeFilter "upcoming"}}>⏭ Upcoming</option>
              <option value="past" selected={{eq this.timeFilter "past"}}>✅ Past</option>
            </select>
          </div>

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
        {{else if this.events.length}}
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
      </div>
    {{/if}}
  </template>
}
