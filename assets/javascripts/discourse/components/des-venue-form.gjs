import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { on } from "@ember/modifier";
import { fn } from "@ember/helper";
import { eq } from "truth-helpers";

export default class DesVenueForm extends Component {
  @tracked formData = null;
  @tracked tracks = [];
  @tracked newTrack = { name: "", surface: "", environment: "", description: "" };
  @tracked showAddTrack = false;

  trackSurfaces = ["carpet", "astroturf", "grass", "tarmac", "dirt", "mixed"];
  trackEnvironments = ["indoor", "outdoor"];

  get initialFormData() {
    return {
      name: this.args.venue?.name || "",
      address: this.args.venue?.address || "",
      postcode: this.args.venue?.postcode || "",
      track_type: this.args.venue?.track_type || "",
      google_maps_url: this.args.venue?.google_maps_url || "",
      website: this.args.venue?.website || "",
      track_category: this.args.venue?.track_category || "",
      track_surface: this.args.venue?.track_surface || "",
      track_environment: this.args.venue?.track_environment || "",
      description: this.args.venue?.description || "",
      parking_info: this.args.venue?.parking_info || "",
      access_notes: this.args.venue?.access_notes || "",
      has_portaloos: this.args.venue?.has_portaloos || false,
      has_permanent_toilets: this.args.venue?.has_permanent_toilets || false,
      has_bar: this.args.venue?.has_bar || false,
      has_cafe: this.args.venue?.has_cafe || false,
      has_showers: this.args.venue?.has_showers || false,
      has_power_supply: this.args.venue?.has_power_supply || false,
      has_water_supply: this.args.venue?.has_water_supply || false,
      has_camping: this.args.venue?.has_camping || false,
      is_shared: this.args.venue?.is_shared || false
    };
  }

  get currentFormData() {
    return this.formData || this.initialFormData;
  }

  @action
  updateField(field, e) {
    this.formData = { ...this.currentFormData, [field]: e.target.value };
  }

  @action
  toggleFacility(field, e) {
    this.formData = { ...this.currentFormData, [field]: e.target.checked };
  }

  constructor() {
    super(...arguments);
    this.tracks = [...(this.args.venue?.tracks || [])];
  }

  @action
  async save() {
    if (!this.currentFormData.name.trim()) {
      alert("Please enter a venue name");
      return;
    }
    try {
      await this.args.onSave(this.currentFormData);
      this.formData = null;
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action toggleAddTrack() { this.showAddTrack = !this.showAddTrack; this.newTrack = { name: "", surface: "", environment: "", description: "" }; }

  @action updateNewTrackField(field, e) { this.newTrack = { ...this.newTrack, [field]: e.target.value }; }

  @action
  async saveNewTrack() {
    if (!this.args.venue?.id) return;
    try {
      const result = await ajax(`/des/venues/${this.args.venue.id}/tracks.json`, {
        type: "POST", data: this.newTrack
      });
      this.tracks = [...this.tracks, result.track];
      this.showAddTrack = false;
      this.newTrack = { name: "", surface: "", environment: "", description: "" };
    } catch (error) { popupAjaxError(error); }
  }

  @action
  async deleteTrack(track) {
    if (!window.confirm(`Delete track "${track.name || 'Unnamed'}"?`)) return;
    try {
      await ajax(`/des/venues/tracks/${track.id}.json`, { type: "DELETE" });
      this.tracks = this.tracks.filter(t => t.id !== track.id);
    } catch (error) { popupAjaxError(error); }
  }

  <template>
    <div class="des-venue-form">
      <div class="org-form-row">
        <div class="org-form-field">
          <label>Name *</label>
          <input type="text" value={{this.currentFormData.name}} placeholder="e.g. Sheffield Off Road Track" {{on "input" (fn this.updateField "name")}} />
        </div>
        <div class="org-form-field">
          <label>Address</label>
          <input type="text" value={{this.currentFormData.address}} placeholder="Full address" {{on "input" (fn this.updateField "address")}} />
        </div>
        <div class="org-form-field">
          <label>Postcode</label>
          <input type="text" value={{this.currentFormData.postcode}} placeholder="e.g. S6 1LU" {{on "input" (fn this.updateField "postcode")}} />
        </div>
        <div class="org-form-field">
          <label>Track Type</label>
          <select {{on "change" (fn this.updateField "track_type")}}>
            <option value="">Select type...</option>
            <option value="permanent" selected={{eq this.currentFormData.track_type "permanent"}}>🏁 Permanent Track</option>
            <option value="popup" selected={{eq this.currentFormData.track_type "popup"}}>🏗️ Pop-up Track</option>
          </select>
        </div>
      </div>

      <div class="org-form-row">
        <div class="org-form-field">
          <label>Google Maps URL</label>
          <input type="url" value={{this.currentFormData.google_maps_url}} {{on "input" (fn this.updateField "google_maps_url")}} />
        </div>
        <div class="org-form-field">
          <label>Website</label>
          <input type="url" value={{this.currentFormData.website}} {{on "input" (fn this.updateField "website")}} />
        </div>
      </div>

      <div class="org-form-row">
        <div class="org-form-field">
          <label>Track Category</label>
          <select {{on "change" (fn this.updateField "track_category")}}>
            <option value="">Select...</option>
            <option value="offroad" selected={{eq this.currentFormData.track_category "offroad"}}>🌿 Off-Road</option>
            <option value="onroad" selected={{eq this.currentFormData.track_category "onroad"}}>🛣️ On-Road</option>
          </select>
        </div>
        <div class="org-form-field">
          <label>Track Surface</label>
          <select {{on "change" (fn this.updateField "track_surface")}}>
            <option value="">Select...</option>
            {{#each this.trackSurfaces as |ts|}}
              <option value={{ts}} selected={{eq this.currentFormData.track_surface ts}}>{{ts}}</option>
            {{/each}}
          </select>
        </div>
        <div class="org-form-field">
          <label>Track Environment</label>
          <select {{on "change" (fn this.updateField "track_environment")}}>
            <option value="">Select...</option>
            <option value="outdoor" selected={{eq this.currentFormData.track_environment "outdoor"}}>🌳 Outdoor</option>
            <option value="indoor_covered" selected={{eq this.currentFormData.track_environment "indoor_covered"}}>🏠 Indoor</option>
          </select>
        </div>
      </div>

      {{#if @venue.id}}
        <div class="org-form-field" style="margin-top:16px;">
          <label>🏁 Tracks</label>
          {{#if this.tracks.length}}
            <div style="display:flex;flex-direction:column;gap:6px;margin-bottom:8px;">
              {{#each this.tracks as |track|}}
                <div style="display:flex;align-items:center;gap:8px;padding:6px 8px;background:var(--primary-very-low);border-radius:6px;">
                  <span style="flex:1;">
                    <strong>{{if track.name track.name "Unnamed Track"}}</strong>
                    {{#if track.surface}} — {{track.surface}}{{/if}}
                    {{#if track.environment}} ({{track.environment}}){{/if}}
                  </span>
                  <button class="btn btn-danger btn-small" {{on "click" (fn this.deleteTrack track)}}>🗑</button>
                </div>
              {{/each}}
            </div>
          {{else}}
            <p class="field-help">No tracks added yet.</p>
          {{/if}}

          {{#if this.showAddTrack}}
            <div style="border:1px solid var(--primary-low);border-radius:6px;padding:10px;margin-top:8px;">
              <div class="org-form-row">
                <div class="org-form-field">
                  <label>Track Name</label>
                  <input type="text" placeholder="e.g. Astro, Main Track" value={{this.newTrack.name}} {{on "input" (fn this.updateNewTrackField "name")}} />
                </div>
                <div class="org-form-field">
                  <label>Surface</label>
                  <select {{on "change" (fn this.updateNewTrackField "surface")}}>
                    <option value="">Select...</option>
                    {{#each this.trackSurfaces as |s|}}
                      <option value={{s}}>{{s}}</option>
                    {{/each}}
                  </select>
                </div>
                <div class="org-form-field">
                  <label>Environment</label>
                  <select {{on "change" (fn this.updateNewTrackField "environment")}}>
                    <option value="">Select...</option>
                    {{#each this.trackEnvironments as |e|}}
                      <option value={{e}}>{{e}}</option>
                    {{/each}}
                  </select>
                </div>
              </div>
              <div class="org-form-field">
                <label>Description</label>
                <input type="text" placeholder="Optional notes..." value={{this.newTrack.description}} {{on "input" (fn this.updateNewTrackField "description")}} />
              </div>
              <div style="display:flex;gap:8px;margin-top:8px;">
                <button class="btn btn-primary btn-small" {{on "click" this.saveNewTrack}}>✅ Add Track</button>
                <button class="btn btn-default btn-small" {{on "click" this.toggleAddTrack}}>✕ Cancel</button>
              </div>
            </div>
          {{else}}
            <button class="btn btn-default btn-small" style="margin-top:4px;" {{on "click" this.toggleAddTrack}}>➕ Add Track</button>
          {{/if}}
        </div>
      {{/if}}

      <div class="org-form-field">
        <label>Description</label>
        <textarea placeholder="Describe the venue..." {{on "input" (fn this.updateField "description")}}>{{this.currentFormData.description}}</textarea>
      </div>

      <div class="org-form-row">
        <div class="org-form-field">
          <label>Parking Info</label>
          <textarea placeholder="Parking details..." {{on "input" (fn this.updateField "parking_info")}}>{{this.currentFormData.parking_info}}</textarea>
        </div>
        <div class="org-form-field">
          <label>Access Notes</label>
          <textarea placeholder="Any access notes..." {{on "input" (fn this.updateField "access_notes")}}>{{this.currentFormData.access_notes}}</textarea>
        </div>
      </div>

      <div class="org-form-field">
        <label>Facilities</label>
        <div class="venue-facilities-checkboxes">
          <label><input type="checkbox" checked={{this.currentFormData.has_portaloos}} {{on "change" (fn this.toggleFacility "has_portaloos")}} /> 🚽 Portaloos</label>
          <label><input type="checkbox" checked={{this.currentFormData.has_permanent_toilets}} {{on "change" (fn this.toggleFacility "has_permanent_toilets")}} /> 🚻 Permanent Toilets</label>
          <label><input type="checkbox" checked={{this.currentFormData.has_bar}} {{on "change" (fn this.toggleFacility "has_bar")}} /> 🍺 Bar</label>
          <label><input type="checkbox" checked={{this.currentFormData.has_cafe}} {{on "change" (fn this.toggleFacility "has_cafe")}} /> ☕ Café</label>
          <label><input type="checkbox" checked={{this.currentFormData.has_showers}} {{on "change" (fn this.toggleFacility "has_showers")}} /> 🚿 Showers</label>
          <label><input type="checkbox" checked={{this.currentFormData.has_power_supply}} {{on "change" (fn this.toggleFacility "has_power_supply")}} /> ⚡ Power Supply</label>
          <label><input type="checkbox" checked={{this.currentFormData.has_water_supply}} {{on "change" (fn this.toggleFacility "has_water_supply")}} /> 💧 Water Supply</label>
          <label><input type="checkbox" checked={{this.currentFormData.has_camping}} {{on "change" (fn this.toggleFacility "has_camping")}} /> ⛺ Camping</label>
        </div>
      </div>

      <div class="org-form-field">
        <label>
          <input type="checkbox" checked={{this.currentFormData.is_shared}} {{on "change" (fn this.toggleFacility "is_shared")}} />
          🤝 Shared venue — other clubs also use this venue
        </label>
        <p class="field-help">Leave unchecked if this venue is exclusive to your club</p>
      </div>

      <div style="display:flex;gap:8px;margin-top:16px;">
        <button class="btn btn-primary" {{on "click" this.save}}>
          {{#if @saveLabel}}{{@saveLabel}}{{else}}✅ Save Venue{{/if}}
        </button>
        {{#if @onCancel}}
          <button class="btn btn-default" {{on "click" @onCancel}}>✕ Cancel</button>
        {{/if}}
      </div>
    </div>
  </template>
}
