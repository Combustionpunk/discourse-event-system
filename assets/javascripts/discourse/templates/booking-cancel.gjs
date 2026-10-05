import { i18n } from "discourse-i18n";
import DesMeetingsLink from "../components/des-meetings-link";

export default <template>
  <div class="booking-cancel-container">
    <div class="booking-cancel-header">
      <div class="booking-cancel-icon">❌</div>
      <h1>Booking Cancelled</h1>
      <p>Your booking was not completed. No payment has been taken.</p>
    </div>

    <div class="booking-cancel-actions">
      {{#if @controller.model.event.topic_url}}
        <a class="btn btn-primary" href={{@controller.model.event.topic_url}}>
          {{i18n "discourse_event_system.booking.back_to_event"}}
        </a>
      {{/if}}
      <DesMeetingsLink class="btn btn-default" />
    </div>
  </div>
</template>
