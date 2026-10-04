import { LinkTo } from "@ember/routing";

export default <template>
  <div class="booking-confirm-container">
    <div class="events-nav">
      <LinkTo class="btn btn-default" @route="events">📅 Events</LinkTo>
      <LinkTo class="btn btn-default" @route="organisations">🏢 Organisations</LinkTo>
    </div>

    <div class="booking-error">
      <div class="booking-success-icon">❌</div>
      <h1>Payment Cancelled</h1>
      <p class="field-help">Your membership payment was cancelled. No charge was made.</p>
      <div class="booking-success-actions">
        <LinkTo class="btn btn-primary" @route="organisations">
          Browse Organisations
        </LinkTo>
        <LinkTo class="btn btn-default" @route="my-memberships">
          My Memberships
        </LinkTo>
      </div>
    </div>
  </div>
</template>
