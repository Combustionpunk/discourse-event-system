import { LinkTo } from "@ember/routing";

export default <template>
  <div class="booking-cancel-container">
    <div class="booking-cancel-header">
      <div class="booking-cancel-icon">❌</div>
      <h1>Booking Cancelled</h1>
      <p>Your booking was not completed. No payment has been taken.</p>
    </div>

    <div class="booking-cancel-actions">
      <LinkTo class="btn btn-primary" @route="events">
        Browse Events
      </LinkTo>
    </div>
  </div>
</template>
