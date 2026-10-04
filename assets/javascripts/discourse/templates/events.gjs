import { concat, fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { LinkTo } from "@ember/routing";
import { eq, or } from "discourse/truth-helpers";

export default <template>
  <div class="events-container">
    <div class="events-nav">
      <LinkTo class="btn btn-default" @route="my-organisations">🏢 My Organisations</LinkTo>
      <LinkTo class="btn btn-default" @route="racing-profile">🏎️ My Racing Profile</LinkTo>
      <LinkTo class="btn btn-default" @route="my-garage">🚗 My Garage</LinkTo>
      <LinkTo class="btn btn-default" @route="my-bookings">🎟️ My Bookings</LinkTo>
      <LinkTo class="btn btn-default" @route="my-memberships">🎫 My Memberships</LinkTo>
    </div>

    <div class="events-header">
      <h1>{{if @controller.isUpcoming "Upcoming Events" "Past Events"}}</h1>
      {{#if @controller.currentUser.staff}}
        <LinkTo class="btn btn-primary" @route="event-new">+ Create Event</LinkTo>
      {{/if}}
    </div>

    {{!-- Filters --}}
    <div class="events-filters">
      <div class="events-filter-tabs">
        <button
          class="btn {{if @controller.isUpcoming 'btn-primary' 'btn-default'}}"
          {{on "click" (fn @controller.setFilter "upcoming")}}
        >
          📅 Upcoming
        </button>
        <button
          class="btn {{unless @controller.isUpcoming 'btn-primary' 'btn-default'}}"
          {{on "click" (fn @controller.setFilter "past")}}
        >
          🕐 Past
        </button>
      </div>
      <div class="events-filter-selects">
        <select {{on "change" @controller.setOrganisation}}>
          <option value="">All Organisations</option>
          {{#each @controller.model.organisations as |org|}}
            <option selected={{eq (concat org.id "") @controller.organisation_id}} value={{org.id}}>{{org.name}}</option>
          {{/each}}
        </select>
        <select {{on "change" @controller.setEventType}}>
          <option value="">All Event Types</option>
          {{#each @controller.model.event_types as |et|}}
            <option selected={{eq (concat et.id "") @controller.event_type_id}} value={{et.id}}>{{et.name}}</option>
          {{/each}}
        </select>
      </div>
    </div>


    {{#if @controller.model.events.length}}
      <div class="events-list">
        {{#each @controller.model.events as |event|}}
          <div class="event-card">
            <div class="event-card-header">
              <h2 class="event-title">
                <LinkTo @model={{event.id}} @route="event">
                  {{event.title}}
                </LinkTo>
                {{#if (eq event.status "draft")}}
                  <span class="draft-badge">📝 Draft</span>
                {{/if}}
              </h2>
              <span class="event-status event-status--{{event.status}}">
                {{event.status}}
              </span>
            </div>

            <div class="event-meta">
              <span class="event-organisation">
                {{#if event.organisation.logo_url}}<img alt="" class="org-logo org-logo--inline" src={{event.organisation.logo_url}} />{{/if}} {{event.organisation.name}}
              </span>
              {{#if event.venue}}
                <span class="event-venue-inline">
                  📍 {{event.venue.name}}
                </span>
              {{/if}}
              <span class="event-date">
                📅 {{event.formatted_date}}
              </span>
              {{#if event.location}}
                <span class="event-location">
                  📍 {{event.location}}
                </span>
              {{/if}}
            </div>

            <div class="event-classes">
              {{#each event.classes as |cls|}}
                <span class="event-class-badge">
                  {{cls.name}} ({{cls.spaces_remaining}} spaces)
                </span>
              {{/each}}
            </div>

            <div class="event-footer">
              {{#if event.pricing}}
                <span class="event-price">
                  💷 From £{{event.pricing.first_class_price}}
                </span>
              {{/if}}
              <LinkTo class="btn btn-primary" @model={{event.id}} @route="event">
                View Event
              </LinkTo>
            </div>
            {{#if @controller.currentUser.admin}}
              <div class="event-admin-actions" style="margin-top:8px;display:flex;gap:6px;">
                {{#if (eq event.status "draft")}}
                  <button class="btn btn-primary btn-small" {{on "click" (fn @controller.publishEvent event)}}>✅ Publish</button>
                {{/if}}
                {{#if (or (eq event.status "draft") (eq event.status "cancelled"))}}
                  <button class="btn btn-danger btn-small" {{on "click" (fn @controller.deleteEvent event)}}>🗑 Delete</button>
                {{/if}}
              </div>
            {{/if}}
          </div>
        {{/each}}
      </div>
    {{else}}
      <div class="events-empty">
        <p>No {{if @controller.isUpcoming "upcoming" "past"}} events found.</p>
      </div>
    {{/if}}
  </div>
</template>
