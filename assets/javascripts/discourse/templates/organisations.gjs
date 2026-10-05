import { LinkTo } from "@ember/routing";
import DesMeetingsLink from "../components/des-meetings-link";

export default <template>
  <div class="organisations-container">
    <div class="events-nav">
      <DesMeetingsLink class="btn btn-default" />
      <LinkTo class="btn btn-default" @route="my-bookings">🎟 My Bookings</LinkTo>
      <LinkTo class="btn btn-default" @route="organisations">🏢 Organisations</LinkTo>
      <LinkTo class="btn btn-primary" @route="organisation-new">+ New Organisation</LinkTo>
    </div>

    <div class="organisations-header">
      <h1>Organisations</h1>
    </div>

    {{#if @controller.model.length}}
      <div class="organisations-list">
        {{#each @controller.model as |org|}}
          <div class="org-card">
            <div class="org-card-header">
              <h2>
                <LinkTo @model={{org.id}} @route="organisation">
                  {{#if org.logo_url}}<img alt="" class="org-logo org-logo--small" src={{org.logo_url}} />{{/if}}
                  {{org.name}}
                </LinkTo>
              </h2>
              <span class="org-status org-status--{{org.status}}">
                {{org.status}}
              </span>
            </div>
            {{#if org.description}}
              <p class="org-description">{{org.description}}</p>
            {{/if}}
            <div class="org-meta">
              {{#if org.email}}
                <span>✉️ {{org.email}}</span>
              {{/if}}
              {{#if org.website}}
                <span>🌐 <a href={{org.website}} rel="noopener noreferrer" target="_blank">{{org.website}}</a></span>
              {{/if}}
            </div>
            <div style="margin-top: 12px;">
              <LinkTo class="btn btn-small btn-default" @model={{org.id}} @route="organisation">
                View Organisation →
              </LinkTo>
            </div>
          </div>
        {{/each}}
      </div>
    {{else}}
      <div class="events-empty">
        <p>No organisations yet.</p>
        <LinkTo class="btn btn-primary" @route="organisation-new">
          Create Organisation
        </LinkTo>
      </div>
    {{/if}}
  </div>
</template>
