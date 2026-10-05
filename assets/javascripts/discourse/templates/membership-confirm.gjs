import { LinkTo } from "@ember/routing";
import DesMeetingsLink from "../components/des-meetings-link";

export default <template>
  <div class="booking-confirm-container">
    <div class="events-nav">
      <DesMeetingsLink class="btn btn-default" />
      <LinkTo class="btn btn-default" @route="organisations">🏢 Organisations</LinkTo>
    </div>

    {{#if @controller.model.redirecting}}
      <div class="booking-success">
        <p>Redirecting to family setup...</p>
      </div>
    {{else if @controller.model.success}}
      <div class="booking-success">
        <div class="booking-success-icon">🎉</div>
        <h1>Membership Confirmed!</h1>
        <p>You are now a member of <strong>{{@controller.model.organisation.name}}</strong>.</p>
        <p class="field-help">You've been added to the organisation's member group.</p>
        <div class="booking-success-actions">
          <LinkTo class="btn btn-primary" @route="my-memberships">
            🎫 View My Memberships
          </LinkTo>
          <LinkTo class="btn btn-default" @model={{@controller.model.organisation.id}} @route="organisation">
            View Organisation
          </LinkTo>
        </div>
      </div>
    {{else}}
      <div class="booking-error">
        <div class="booking-success-icon">❌</div>
        <h1>Confirmation Failed</h1>
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
