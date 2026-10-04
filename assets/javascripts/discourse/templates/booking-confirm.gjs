import { LinkTo } from "@ember/routing";
import { eq } from "discourse/truth-helpers";

export default <template>
  <div class="booking-confirm-container">

    {{#if (eq @controller.model.status "confirmed")}}
      <div class="booking-confirm-header">
        <div class="booking-confirm-icon">✅</div>
        <h1>Booking Confirmed!</h1>
        <p>Your booking for <strong>{{@controller.model.event.title}}</strong> has been confirmed and payment received.</p>
      </div>
    {{else if (eq @controller.model.status "pending")}}
      <div class="booking-confirm-header">
        <div class="booking-confirm-icon">⏳</div>
        <h1>Booking Pending</h1>
        <p>Your booking for <strong>{{@controller.model.event.title}}</strong> is being processed. You will receive a confirmation email shortly.</p>
      </div>
    {{else}}
      <div class="booking-confirm-header">
        <div class="booking-confirm-icon">📋</div>
        <h1>Booking Summary</h1>
      </div>
    {{/if}}

    <div class="booking-confirm-details">
      <h2>Booking Details</h2>

      <div class="booking-detail-item">
        <strong>Event:</strong> {{@controller.model.event.title}}
      </div>

      {{#if @controller.model.event.formatted_date}}
        <div class="booking-detail-item">
          <strong>📅 Date:</strong> {{@controller.model.event.formatted_date}}
        </div>
      {{/if}}

      {{#if @controller.model.event.location}}
        <div class="booking-detail-item">
          <strong>📍 Location:</strong> {{@controller.model.event.location}}
        </div>
      {{/if}}

      <div class="booking-detail-item">
        <strong>Status:</strong>
        <span class="booking-status booking-status--{{@controller.model.status}}">
          {{@controller.model.status}}
        </span>
      </div>

      <div class="booking-detail-item">
        <strong>Classes Booked:</strong>
        <ul class="booking-classes-list">
          {{#each @controller.model.classes as |cls|}}
            <li>
              <span class="booking-class-badge">{{cls.class_name}}</span>
              {{#if cls.transponder_number}}
                <span class="transponder-number">📡 {{cls.transponder_number}}</span>
              {{/if}}
              <span class="booking-class-amount">£{{cls.amount_charged}}</span>
            </li>
          {{/each}}
        </ul>
      </div>

      <div class="booking-detail-item">
        <strong>Total Paid:</strong>
        <span class="booking-total">£{{@controller.model.amount_paid}}</span>
      </div>

      {{#if @controller.model.brca_membership_number}}
        <div class="booking-detail-item">
          <strong>BRCA Number:</strong> {{@controller.model.brca_membership_number}}
        </div>
      {{/if}}
    </div>


    {{#if @controller.model.event.id}}
      <div class="booking-calendar-prompt">
        <h3>📅 Add to your calendar?</h3>
        <div class="calendar-options">
          <a class="btn btn-default" href="https://calendar.google.com/calendar/render?action=TEMPLATE&text={{@controller.model.event.title}}" rel="noopener noreferrer" target="_blank">
            📅 Google Calendar
          </a>
          <a class="btn btn-default" href="https://outlook.live.com/calendar/0/deeplink/compose?rru=addevent&subject={{@controller.model.event.title}}" rel="noopener noreferrer" target="_blank">
            📅 Outlook.com
          </a>
        </div>
      </div>
    {{/if}}

    <div class="booking-confirm-actions">
      <LinkTo class="btn btn-primary" @route="my-bookings">
        🎟 View My Bookings
      </LinkTo>
      {{#if @controller.model.event.topic_url}}
        <a class="btn btn-default" href={{@controller.model.event.topic_url}}>
          💬 Discuss this Event
        </a>
      {{/if}}
      <LinkTo class="btn btn-default" @route="events">
        📅 Browse More Events
      </LinkTo>
    </div>
  </div>
</template>
