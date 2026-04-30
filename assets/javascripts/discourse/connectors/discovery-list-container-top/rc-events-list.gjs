import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { on } from "@ember/modifier";
import { fn } from "@ember/helper";
import { eq } from "truth-helpers";

export default class RcEventsList extends Component {
  @tracked events = [];
  @tracked filter = "default";
  @tracked loading = true;
  @tracked isRcMeetings = false;

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
      const response = await ajax("/des/rc-events-topic-list.json", {
        data: this.filter !== "default" ? { filter: this.filter } : {}
      });
      this.events = response.topics || [];
    } catch {
      this.events = [];
    } finally {
      this.loading = false;
    }
  }

  @action
  async setFilter(f) {
    this.filter = f;
    await this.loadEvents();
  }

  <template>
    {{#if this.isRcMeetings}}
      <div class="rc-events-list">
        <div class="rc-events-filters">
          <button class="btn {{if (eq this.filter 'default') 'btn-primary' 'btn-default'}} btn-small" {{on "click" (fn this.setFilter "default")}}>
            📅 Upcoming & Today
          </button>
          <button class="btn {{if (eq this.filter 'today') 'btn-primary' 'btn-default'}} btn-small" {{on "click" (fn this.setFilter "today")}}>
            📍 Today
          </button>
          <button class="btn {{if (eq this.filter 'upcoming') 'btn-primary' 'btn-default'}} btn-small" {{on "click" (fn this.setFilter "upcoming")}}>
            ⏭ Upcoming
          </button>
          <button class="btn {{if (eq this.filter 'past') 'btn-primary' 'btn-default'}} btn-small" {{on "click" (fn this.setFilter "past")}}>
            ✅ Past
          </button>
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
          <div class="rc-events-empty">No events found.</div>
        {{/if}}
      </div>
    {{/if}}
  </template>
}
