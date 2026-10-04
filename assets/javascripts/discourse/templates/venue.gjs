import { get } from "@ember/helper";
import { on } from "@ember/modifier";
import { LinkTo } from "@ember/routing";
import { eq, gt } from "discourse/truth-helpers";
import DesVenueForm from "../components/des-venue-form";

export default <template>
  <div class="venue-detail-container">
    <div class="events-nav">
      <LinkTo class="btn btn-default" @route="venues">📍 All Venues</LinkTo>
    </div>

    <div style="display:flex;gap:8px;align-items:center;flex-wrap:wrap;">
      {{#if @controller.model.venue.can_edit}}
        <button class="btn btn-default btn-small" {{on "click" @controller.toggleEdit}}>{{if @controller.editMode "Cancel" "✏️ Edit Venue"}}</button>
      {{/if}}
      {{#if @controller.currentUser}}
        {{#unless @controller.model.venue.can_edit}}
          <button class="btn btn-default btn-small" {{on "click" @controller.toggleSuggest}}>{{if @controller.suggestMode "Cancel" "💡 Suggest Edit"}}</button>
        {{/unless}}
        {{#if @controller.canClaim}}
          <button class="btn btn-default btn-small" {{on "click" @controller.toggleClaimForm}}>
            🏠 {{if @controller.showClaimForm "Cancel" "Claim this Venue"}}
          </button>
        {{/if}}
      {{/if}}
    </div>

    {{#if @controller.showClaimForm}}
      <div style="background:var(--primary-very-low);border-radius:6px;padding:12px;margin:8px 0;">
        <p style="margin:0 0 8px;"><strong>🏠 Claim this venue for your organisation</strong></p>
        {{#if (gt @controller.model.myOrgs.length 1)}}
          <div class="org-form-field">
            <label>Select Organisation</label>
            <select {{on "change" @controller.updateSelectedClaimOrg}}>
              <option value="">Select...</option>
              {{#each @controller.model.myOrgs as |org|}}
                <option value={{org.id}}>{{org.name}}</option>
              {{/each}}
            </select>
          </div>
        {{else}}
          <p style="margin:0 0 8px;color:var(--primary-medium);">Claiming for: <strong>{{get @controller.model.myOrgs "0.name"}}</strong></p>
        {{/if}}
        <button class="btn btn-primary btn-small" {{on "click" @controller.submitClaim}}>✅ Submit Claim</button>
      </div>
    {{/if}}

    {{#if @controller.claimSent}}
      <div style="background:var(--success-low);border:1px solid var(--success);border-radius:6px;padding:10px 14px;margin:12px 0;color:var(--success);">
        ✅ Claim submitted! An admin will review it shortly.
      </div>
    {{/if}}

    {{#if (eq @controller.model.venue.claim_status "pending")}}
      <div style="background:var(--highlight-low);padding:8px 12px;border-radius:6px;margin:8px 0;">
        ⏳ Claim pending approval
      </div>
    {{/if}}

    {{#if (eq @controller.model.venue.claim_status "approved")}}
      <div style="margin:8px 0;">
        🏠 Home venue of <strong>{{@controller.model.venue.claimed_organisation_name}}</strong>
      </div>
    {{/if}}

    {{#if @controller.model.venue.is_stub}}
      <div class="venue-stub-banner" style="background:var(--highlight-low);border:1px solid var(--highlight);border-radius:6px;padding:10px 14px;margin:12px 0;color:var(--highlight-high);">
        📍 This venue was automatically imported from BRCA data and may be incomplete.
        Help the community by filling in the details below!
      </div>
    {{/if}}

    {{#if @controller.suggestionSent}}
      <div style="background:var(--success-low);border:1px solid var(--success);border-radius:6px;padding:10px 14px;margin:12px 0;color:var(--success);">
        ✅ Thank you! Your suggestion has been submitted for review.
      </div>
    {{/if}}

    <h1>{{@controller.model.venue.name}}</h1>

    {{#if @controller.editMode}}
      <div class="venue-form event-form-section">
        <DesVenueForm
          @onCancel={{@controller.toggleEdit}}
          @onSave={{@controller.saveVenue}}
          @saveLabel="💾 Save Changes"
          @venue={{@controller.editData}}
        />
      </div>
    {{/if}}

    {{#if @controller.suggestMode}}
      <div class="venue-form event-form-section">
        <DesVenueForm
          @onCancel={{@controller.toggleSuggest}}
          @onSave={{@controller.submitSuggestion}}
          @saveLabel="💡 Submit Suggestion"
          @venue={{@controller.suggestData}}
        />
      </div>
    {{/if}}


    <div class="venue-detail-meta">
      {{#if @controller.model.venue.address}}
        <div class="venue-detail-item">📍 {{@controller.model.venue.address}}</div>
      {{/if}}
      {{#if @controller.model.venue.google_maps_url}}
        <div class="venue-detail-item">
          <a href={{@controller.model.venue.google_maps_url}} rel="noopener noreferrer" target="_blank">🗺️ View on Google Maps</a>
        </div>
      {{/if}}
      {{#if @controller.model.venue.website}}
        <div class="venue-detail-item">
          <a href={{@controller.model.venue.website}} rel="noopener noreferrer" target="_blank">🌐 Website</a>
        </div>
      {{/if}}
      {{#if @controller.model.venue.organisation_name}}
        <div class="venue-detail-item">🏢 {{@controller.model.venue.organisation_name}}</div>
      {{/if}}
    </div>

    {{#if @controller.model.venue.tracks.length}}
      <div class="venue-tracks">
        <h3>🏁 Tracks</h3>
        {{#each @controller.model.venue.tracks as |track|}}
          <div class="venue-track">
            {{#if track.name}}<span class="venue-track-name">🏁 {{track.name}}</span>{{/if}}
            {{#if track.surface}}<span class="rc-event-badge rc-surface-badge">{{track.surface}}</span>{{/if}}
            {{#if track.environment}}<span class="rc-event-badge rc-environment-badge">{{track.environment}}</span>{{/if}}
            {{#if track.description}}<p class="venue-track-description">{{track.description}}</p>{{/if}}
          </div>
        {{/each}}
      </div>
    {{/if}}

    {{#if @controller.model.venue.description}}
      <div class="event-description-box">{{@controller.model.venue.description}}</div>
    {{/if}}

    <div class="venue-facilities">
      <h3>Facilities</h3>
      <div class="venue-facilities-grid">
        <div class="facility-item {{if @controller.model.venue.has_permanent_toilets 'facility--yes' 'facility--no'}}">🚻 Permanent Toilets</div>
        <div class="facility-item {{if @controller.model.venue.has_portaloos 'facility--yes' 'facility--no'}}">🚽 Portaloos</div>
        <div class="facility-item {{if @controller.model.venue.has_bar 'facility--yes' 'facility--no'}}">🍺 Bar</div>
        <div class="facility-item {{if @controller.model.venue.has_cafe 'facility--yes' 'facility--no'}}">☕ Café</div>
        <div class="facility-item {{if @controller.model.venue.has_showers 'facility--yes' 'facility--no'}}">🚿 Showers</div>
        <div class="facility-item {{if @controller.model.venue.has_power_supply 'facility--yes' 'facility--no'}}">⚡ Power Supply</div>
        <div class="facility-item {{if @controller.model.venue.has_water_supply 'facility--yes' 'facility--no'}}">💧 Water Supply</div>
        <div class="facility-item {{if @controller.model.venue.has_camping 'facility--yes' 'facility--no'}}">⛺ Camping</div>
        <div class="facility-item {{if @controller.model.venue.has_track_shop 'facility--yes' 'facility--no'}}">🛒 Track Shop</div>
      </div>
    </div>

    {{#if @controller.model.venue.parking_info}}
      <div class="venue-info-section">
        <h3>🅿️ Parking</h3>
        <p>{{@controller.model.venue.parking_info}}</p>
      </div>
    {{/if}}

    {{#if @controller.model.venue.access_notes}}
      <div class="venue-info-section">
        <h3>ℹ️ Access Notes</h3>
        <p>{{@controller.model.venue.access_notes}}</p>
      </div>
    {{/if}}

    {{#if @controller.model.upcoming_events.length}}
      <div class="venue-events">
        <h3>📅 Upcoming Events</h3>
        {{#each @controller.model.upcoming_events as |event|}}
          <div class="venue-event-item">
            {{#if (eq event.type "imported")}}
              <a href={{event.booking_url}} rel="noopener noreferrer" target="_blank">{{event.title}}</a>
              <span class="rc-event-badge rc-event-badge--brca">BRCA</span>
            {{else}}
              <LinkTo @model={{event.id}} @route="event">{{event.title}}</LinkTo>
            {{/if}}
            <span class="venue-event-date">📅 {{event.formatted_date}}</span>
            <span class="field-help">{{event.organisation_name}}</span>
          </div>
        {{/each}}
      </div>
    {{/if}}
  </div>
</template>
