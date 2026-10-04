import { LinkTo } from "@ember/routing";

export default <template>
  <div class="my-organisations-container">
    <div class="events-nav">
      <LinkTo class="btn btn-default" @route="my-organisations">🏢 My Organisations</LinkTo>
      <LinkTo class="btn btn-default" @route="racing-profile">🏎️ My Racing Profile</LinkTo>
      <LinkTo class="btn btn-default" @route="my-garage">🚗 My Garage</LinkTo>
      <LinkTo class="btn btn-default" @route="my-bookings">🎟️ My Bookings</LinkTo>
      <LinkTo class="btn btn-default" @route="my-memberships">🎫 My Memberships</LinkTo>
    </div>

    <h1>🏢 My Organisations</h1>

    {{#if @controller.model.organisations.length}}
      <div class="my-orgs-list">
        {{#each @controller.model.organisations as |org|}}
          <div class="my-org-card">
            <div class="my-org-info">
              <h3>
                <LinkTo @model={{org.id}} @route="organisation">{{org.name}}</LinkTo>
              </h3>
              {{#if org.description}}
                <p class="field-help">{{org.description}}</p>
              {{/if}}
              <div style="display:flex; gap:8px; margin-top:8px; flex-wrap:wrap;">
                {{#if org.membership}}
                  <span class="membership-status-badge membership-status-badge--active">
                    🎫 {{org.membership.type}}
                  </span>
                  <span class="field-help">
                    expires {{@controller.formatDate org.membership.expires_at}}
                  </span>
                {{/if}}
                {{#each org.positions as |position|}}
                  <span class="rule-type-badge rule-type-badge--driveline">
                    👥 {{position}}
                  </span>
                {{/each}}
              </div>
            </div>
            <LinkTo class="btn btn-small btn-default" @model={{org.id}} @route="organisation">
              View →
            </LinkTo>
          </div>
        {{/each}}
      </div>
    {{else}}
      <div class="empty-state">
        <p>You're not a member of any organisations yet.</p>
        <LinkTo class="btn btn-primary" @route="organisations">Browse Organisations</LinkTo>
      </div>
    {{/if}}
  </div>
</template>
