import { LinkTo } from "@ember/routing";

export default <template>
  <div class="booking-confirm-container">
    {{#if @controller.model.success}}
      <div class="booking-success">
        <div class="booking-success-icon">🎉</div>
        <h1>Membership Renewed!</h1>
        <p>Your membership for <strong>{{@controller.model.organisation.name}}</strong> has been renewed.</p>
        <div class="booking-success-actions">
          <LinkTo class="btn btn-primary" @route="my-memberships">
            🎫 View My Memberships
          </LinkTo>
        </div>
      </div>
    {{else}}
      <div class="booking-error">
        <div class="booking-success-icon">❌</div>
        <h1>Renewal Failed</h1>
        <p>{{@controller.model.error}}</p>
        <div class="booking-success-actions">
          <LinkTo class="btn btn-default" @route="my-memberships">
            View My Memberships
          </LinkTo>
        </div>
      </div>
    {{/if}}
  </div>
</template>
