import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { LinkTo } from "@ember/routing";
import { eq } from "discourse/truth-helpers";
import DesMeetingsLink from "../components/des-meetings-link";

export default <template>
  <div class="my-bookings-container">
    <div class="events-nav">
      <LinkTo class="btn btn-default" @route="my-organisations">🏢 My Organisations</LinkTo>
      <LinkTo class="btn btn-default" @route="racing-profile">🏎️ My Racing Profile</LinkTo>
      <LinkTo class="btn btn-default" @route="my-garage">🚗 My Garage</LinkTo>
      <LinkTo class="btn btn-default" @route="my-bookings">🎟️ My Bookings</LinkTo>
      <LinkTo class="btn btn-default" @route="my-memberships">🎫 My Memberships</LinkTo>
    </div>

    <h1>🎟️ My Bookings</h1>

    {{#if @controller.model.upcoming.length}}
      <h2>Upcoming Events</h2>
      {{#each @controller.model.upcoming as |booking|}}
        <div class="booking-card booking-card--{{booking.status}}">
          <div class="booking-card-header">
            <div>
              <h3>{{booking.event.title}}</h3>
              <span class="field-help">
                {{booking.event.formatted_date}}
                {{#if booking.event.organisation_name}} — {{booking.event.organisation_name}}{{/if}}
                {{#unless booking.is_own}} — booked for <strong>{{booking.username}}</strong>{{/unless}}
              </span>
            </div>
            <span class="booking-status booking-status--{{booking.status}}">{{booking.status}}</span>
          </div>
          <div class="booking-classes-list">
            {{#each booking.classes as |bc|}}
              <div class="booking-class-item">
                <span class="booking-class-badge">{{bc.class_name}}</span>
                {{#if bc.manufacturer_name}}<span class="field-help">{{bc.manufacturer_name}} {{bc.model_name}}</span>{{/if}}
                {{#if bc.transponder_number}}<span class="transponder-number">📡 {{bc.transponder_number}}</span>{{/if}}
                <span class="booking-status booking-status--{{bc.status}}">{{bc.status}}</span>
                {{#unless (eq booking.status "cancelled")}}
                  <button class="btn btn-small btn-default" {{on "click" (fn @controller.startChangeCar booking bc)}}>🔄 Change Car</button>
                {{/unless}}
              </div>
            {{/each}}
          </div>
          {{#unless (eq booking.status "cancelled")}}
            <div class="booking-card-actions">
              <button class="btn btn-small btn-danger" {{on "click" (fn @controller.cancelBooking booking.id)}}>Cancel Booking</button>
            </div>
          {{/unless}}
        </div>
      {{/each}}
    {{/if}}

    {{#if @controller.model.past.length}}
      <h2>Past Events</h2>
      {{#each @controller.model.past as |booking|}}
        <div class="booking-card booking-card--past">
          <div class="booking-card-header">
            <div>
              <h3>{{booking.event.title}}</h3>
              <span class="field-help">
                {{booking.event.formatted_date}}
                {{#unless booking.is_own}} — <strong>{{booking.username}}</strong>{{/unless}}
              </span>
            </div>
            <span class="booking-status booking-status--{{booking.status}}">{{booking.status}}</span>
          </div>
          <div class="booking-classes-list">
            {{#each booking.classes as |bc|}}
              <div class="booking-class-item">
                <span class="booking-class-badge">{{bc.class_name}}</span>
                {{#if bc.manufacturer_name}}<span class="field-help">{{bc.manufacturer_name}} {{bc.model_name}}</span>{{/if}}
                {{#if bc.transponder_number}}<span class="transponder-number">📡 {{bc.transponder_number}}</span>{{/if}}
              </div>
            {{/each}}
          </div>
        </div>
      {{/each}}
    {{/if}}

    {{#unless @controller.model.bookings.length}}
      <div class="empty-state">
        <p>You don't have any bookings yet.</p>
        <DesMeetingsLink class="btn btn-primary" />
      </div>
    {{/unless}}

    {{!-- Waitlist --}}
    {{#if @controller.model.waitlist.length}}
      <h2>📋 Waitlist</h2>
      {{#each @controller.model.waitlist as |entry|}}
        <div class="booking-card">
          <div class="booking-card-header">
            <div>
              <h3>{{entry.event.title}}</h3>
              <span class="field-help">{{entry.event.formatted_date}} — {{entry.class_name}}</span>
            </div>
            <span class="booking-status booking-status--waitlist">Position #{{entry.position}}</span>
          </div>
          <div class="booking-card-actions">
            <button class="btn btn-small btn-danger" {{on "click" (fn @controller.leaveWaitlist entry.id)}}>Leave Waitlist</button>
          </div>
        </div>
      {{/each}}
    {{/if}}

    {{!-- Car Change Modal --}}
    {{#if @controller.changingCarBookingId}}
      <div class="car-selection-overlay">
        <div class="car-selection-modal">
          <h2>🔄 Change Car</h2>
          {{#if @controller.changingCarOptions.length}}
            {{#each @controller.changingCarOptions as |car|}}
              <div class="family-search-result" role="button" {{on "click" (fn @controller.confirmChangeCar car.id)}}>
                <strong>{{car.friendly_name}}</strong> — {{car.driveline}} — {{car.transponder_number}}
                {{#if car.owner_username}} <span class="field-help">({{car.owner_username}})</span>{{/if}}
              </div>
            {{/each}}
          {{else}}
            <p class="field-help">No eligible cars found.</p>
          {{/if}}
          <button class="btn btn-default" style="margin-top:12px;" {{on "click" @controller.cancelChangeCar}}>Cancel</button>
        </div>
      </div>
    {{/if}}
  </div>
</template>
