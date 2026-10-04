import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { LinkTo } from "@ember/routing";
import { eq } from "discourse/truth-helpers";
import DesVenueForm from "../components/des-venue-form";

export default <template>
  <div class="venues-container">
    <div class="events-nav">
      <LinkTo class="btn btn-default" @route="events">📅 Events</LinkTo>
      <LinkTo class="btn btn-default" @route="organisations">🏢 Organisations</LinkTo>
      <LinkTo class="btn btn-default" @route="venues">📍 Venues</LinkTo>
    </div>

    <div class="manage-section-header">
      <h1>📍 Venues</h1>
      {{#if @controller.currentUser.admin}}
        <button class="btn btn-primary" {{on "click" @controller.toggleAdminAddVenue}}>
          {{if @controller.showAdminAddVenue "✕ Cancel" "+ Add Venue"}}
        </button>
      {{else if @controller.canSuggest}}
        <button class="btn btn-default" {{on "click" @controller.toggleForm}}>
          {{if @controller.showForm "✕ Cancel" "➕ Suggest a Venue"}}
        </button>
      {{/if}}
    </div>

    {{#if @controller.showAdminAddVenue}}
      <div class="venue-form event-form-section">
        <h2>Add Venue</h2>
        <DesVenueForm
          @onCancel={{@controller.toggleAdminAddVenue}}
          @onSave={{@controller.adminSaveVenue}}
          @saveLabel="✅ Create Venue"
        />
      </div>
    {{/if}}

    {{#if @controller.showForm}}
      <div class="venue-form event-form-section">
        <h2>Suggest a Venue</h2>
        <p class="field-help">Your venue suggestion will be reviewed by an admin before appearing publicly.</p>
        <div class="org-form-field">
          <label>Organisation *</label>
          <select {{on "change" (fn @controller.updateField "created_by_organisation_id")}}>
            {{#each @controller.model.myOrgs as |org|}}
              <option value={{org.id}}>{{org.name}}</option>
            {{/each}}
          </select>
        </div>
        <DesVenueForm
          @onCancel={{@controller.toggleForm}}
          @onSave={{@controller.saveVenue}}
          @saveLabel="Submit Venue"
        />
      </div>
    {{/if}}

    <div style="display:flex;align-items:center;gap:8px;margin-bottom:16px;">
      <div class="venue-view-toggle" style="display:flex;gap:8px;">
        <button class="btn btn-small {{if (eq @controller.viewMode 'list') 'btn-primary' 'btn-default'}}" {{on "click" (fn @controller.setViewMode "list")}}>☰ List</button>
        <button class="btn btn-small {{if (eq @controller.viewMode 'map') 'btn-primary' 'btn-default'}}" {{on "click" (fn @controller.setViewMode "map")}}>🗺️ Map</button>
      </div>
      <button class="btn btn-small btn-default" title="Icon Key" {{on "click" @controller.toggleIconKey}}>❓ Icon Key</button>
    </div>

    {{#if @controller.showIconKey}}
      <div class="venue-icon-key-overlay" {{on "click" @controller.toggleIconKey}}>
        <div class="venue-icon-key-modal" {{on "click" @controller.stopPropagation}}>
          <div class="venue-icon-key-header">
            <h3>Venue Icon Key</h3>
            <button class="btn btn-small btn-default" {{on "click" @controller.toggleIconKey}}>✕</button>
          </div>
          <div class="venue-icon-key-body">
            <div class="icon-key-section">
              <h4>Track Type</h4>
              <div class="icon-key-row"><span>🏁</span><span>Permanent Track</span></div>
              <div class="icon-key-row"><span>🏗️</span><span>Pop-up Track</span></div>
            </div>
            <div class="icon-key-section">
              <h4>Environment</h4>
              <div class="icon-key-row"><span>🌳</span><span>Outdoor</span></div>
              <div class="icon-key-row"><span>🏠</span><span>Indoor / Covered</span></div>
            </div>
            <div class="icon-key-section">
              <h4>Surface</h4>
              <div class="icon-key-row"><span>🟫</span><span>Carpet</span></div>
              <div class="icon-key-row"><span>🌿</span><span>Astroturf</span></div>
              <div class="icon-key-row"><span>🍃</span><span>Grass</span></div>
              <div class="icon-key-row"><span>⬛</span><span>Tarmac</span></div>
              <div class="icon-key-row"><span>🔀</span><span>Mixed Surface</span></div>
            </div>
            <div class="icon-key-section">
              <h4>Facilities</h4>
              <div class="icon-key-row"><span>🚻</span><span>Permanent Toilets</span></div>
              <div class="icon-key-row"><span>🚽</span><span>Portaloos</span></div>
              <div class="icon-key-row"><span>☕</span><span>Café</span></div>
              <div class="icon-key-row"><span>🍺</span><span>Bar</span></div>
              <div class="icon-key-row"><span>🚿</span><span>Showers</span></div>
              <div class="icon-key-row"><span>⚡</span><span>Power Supply</span></div>
              <div class="icon-key-row"><span>💧</span><span>Water Supply</span></div>
              <div class="icon-key-row"><span>⛺</span><span>Camping</span></div>
            </div>
          </div>
        </div>
      </div>
    {{/if}}

    {{#if (eq @controller.viewMode "map")}}
      <div id="venues-map" style="height:550px;width:100%;border-radius:8px;overflow:hidden;margin-bottom:24px;"></div>
    {{/if}}

    {{#if (eq @controller.viewMode "list")}}
    {{#if @controller.model.venues.length}}
      <div class="venue-community-banner" style="background:var(--tertiary-low);border:1px solid var(--tertiary);border-radius:8px;padding:12px 16px;margin:16px 0;display:flex;align-items:center;gap:12px;">
        <span style="font-size:1.5em;">📍</span>
        <div>
          <strong>Help us improve our venue directory!</strong>
          <p style="margin:4px 0 0;color:var(--primary-medium);font-size:0.9em;">
            Many venues were automatically imported and may have incomplete information.
            Visit any venue page and click <strong>💡 Suggest Edit</strong> to help fill in
            track details, facilities and more. Your contributions help the whole RC community!
          </p>
        </div>
      </div>

      <div class="venues-grid">
        {{#each @controller.model.venues as |venue|}}
          <LinkTo class="venue-card-link" @model={{venue.id}} @route="venue">
            <div class="venue-card">
              <h3>{{venue.name}}</h3>
              {{#if venue.address}}<p class="venue-address">📍 {{venue.address}}</p>{{/if}}
              <div class="venue-badges">
                {{#each venue.tracks as |track|}}
                  {{#if track.surface}}<span class="venue-badge venue-badge--surface">{{track.surface}}</span>{{/if}}
                  {{#if track.environment}}<span class="venue-badge venue-badge--environment">{{track.environment}}</span>{{/if}}
                {{/each}}
              </div>
              <div class="venue-facilities-icons">
                {{#if venue.has_permanent_toilets}}🚻{{/if}}
                {{#if venue.has_portaloos}}🚽{{/if}}
                {{#if venue.has_bar}}🍺{{/if}}
                {{#if venue.has_showers}}🚿{{/if}}
                {{#if venue.has_power_supply}}⚡{{/if}}
                {{#if venue.has_water_supply}}💧{{/if}}
                {{#if venue.has_camping}}⛺{{/if}}
                {{#if venue.has_track_shop}}🛒{{/if}}
              </div>
            </div>
          </LinkTo>
        {{/each}}
      </div>
    {{else}}
      <div class="empty-state">
        <p>No venues yet.</p>
      </div>
    {{/if}}
    {{/if}}
  </div>
</template>
