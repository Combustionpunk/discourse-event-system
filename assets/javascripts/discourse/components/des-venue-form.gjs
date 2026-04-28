import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { on } from "@ember/modifier";
import { fn } from "@ember/helper";
import { eq } from "truth-helpers";

export default class DesVenueForm extends Component {
  @tracked formData = {
    name: "", address: "", google_maps_url: "", website: "",
    track_category: "", track_surface: "", track_environment: "",
    description: "", parking_info: "", access_notes: "",
    has_portaloos: false, has_permanent_toilets: false, has_bar: false,
    has_showers: false, has_power_supply: false, has_water_supply: false,
    has_camping: false, is_shared: false
  };

  trackSurfaces = ["carpet", "astroturf", "grass", "tarmac", "mixed"];

  constructor() {
    super(...arguments);
    if (this.args.venue) {
      this.formData = { ...this.formData, ...this.args.venue };
    }
  }

  @action
  updateField(field, e) {
    this.formData = { ...this.formData, [field]: e.target.value };
  }

  @action
  toggleFacility(field, e) {
    this.formData = { ...this.formData, [field]: e.target.checked };
  }

  @action
  async save() {
    if (!this.formData.name.trim()) {
      alert("Please enter a venue name");
      return;
    }
    try {
      await this.args.onSave(this.formData);
      this.formData = {
        name: "", address: "", google_maps_url: "", website: "",
        track_category: "", track_surface: "", track_environment: "",
        description: "", parking_info: "", access_notes: "",
        has_portaloos: false, has_permanent_toilets: false, has_bar: false,
        has_showers: false, has_power_supply: false, has_water_supply: false,
        has_camping: false, is_shared: false
      };
    } catch (error) {
      popupAjaxError(error);
    }
  }

  <template>
    <div class="des-venue-form">
      <div class="org-form-row">
        <div class="org-form-field">
          <label>Name *</label>
          <input type="text" value={{this.formData.name}} placeholder="e.g. Sheffield Off Road Track" {{on "input" (fn this.updateField "name")}} />
        </div>
        <div class="org-form-field">
          <label>Address</label>
          <input type="text" value={{this.formData.address}} placeholder="Full address" {{on "input" (fn this.updateField "address")}} />
        </div>
      </div>

      <div class="org-form-row">
        <div class="org-form-field">
          <label>Google Maps URL</label>
          <input type="url" value={{this.formData.google_maps_url}} {{on "input" (fn this.updateField "google_maps_url")}} />
        </div>
        <div class="org-form-field">
          <label>Website</label>
          <input type="url" value={{this.formData.website}} {{on "input" (fn this.updateField "website")}} />
        </div>
      </div>

      <div class="org-form-row">
        <div class="org-form-field">
          <label>Track Category</label>
          <select {{on "change" (fn this.updateField "track_category")}}>
            <option value="">Select...</option>
            <option value="offroad" selected={{eq this.formData.track_category "offroad"}}>🌿 Off-Road</option>
            <option value="onroad" selected={{eq this.formData.track_category "onroad"}}>🛣️ On-Road</option>
          </select>
        </div>
        <div class="org-form-field">
          <label>Track Surface</label>
          <select {{on "change" (fn this.updateField "track_surface")}}>
            <option value="">Select...</option>
            {{#each this.trackSurfaces as |ts|}}
              <option value={{ts}} selected={{eq this.formData.track_surface ts}}>{{ts}}</option>
            {{/each}}
          </select>
        </div>
        <div class="org-form-field">
          <label>Track Environment</label>
          <select {{on "change" (fn this.updateField "track_environment")}}>
            <option value="">Select...</option>
            <option value="outdoor" selected={{eq this.formData.track_environment "outdoor"}}>🌳 Outdoor</option>
            <option value="indoor_covered" selected={{eq this.formData.track_environment "indoor_covered"}}>🏠 Indoor</option>
          </select>
        </div>
      </div>

      <div class="org-form-field">
        <label>Description</label>
        <textarea placeholder="Describe the venue..." {{on "input" (fn this.updateField "description")}}>{{this.formData.description}}</textarea>
      </div>

      <div class="org-form-row">
        <div class="org-form-field">
          <label>Parking Info</label>
          <textarea placeholder="Parking details..." {{on "input" (fn this.updateField "parking_info")}}>{{this.formData.parking_info}}</textarea>
        </div>
        <div class="org-form-field">
          <label>Access Notes</label>
          <textarea placeholder="Any access notes..." {{on "input" (fn this.updateField "access_notes")}}>{{this.formData.access_notes}}</textarea>
        </div>
      </div>

      <div class="org-form-field">
        <label>Facilities</label>
        <div class="venue-facilities-checkboxes">
          <label><input type="checkbox" checked={{this.formData.has_portaloos}} {{on "change" (fn this.toggleFacility "has_portaloos")}} /> 🚽 Portaloos</label>
          <label><input type="checkbox" checked={{this.formData.has_permanent_toilets}} {{on "change" (fn this.toggleFacility "has_permanent_toilets")}} /> 🚻 Permanent Toilets</label>
          <label><input type="checkbox" checked={{this.formData.has_bar}} {{on "change" (fn this.toggleFacility "has_bar")}} /> 🍺 Bar</label>
          <label><input type="checkbox" checked={{this.formData.has_showers}} {{on "change" (fn this.toggleFacility "has_showers")}} /> 🚿 Showers</label>
          <label><input type="checkbox" checked={{this.formData.has_power_supply}} {{on "change" (fn this.toggleFacility "has_power_supply")}} /> ⚡ Power Supply</label>
          <label><input type="checkbox" checked={{this.formData.has_water_supply}} {{on "change" (fn this.toggleFacility "has_water_supply")}} /> 💧 Water Supply</label>
          <label><input type="checkbox" checked={{this.formData.has_camping}} {{on "change" (fn this.toggleFacility "has_camping")}} /> ⛺ Camping</label>
        </div>
      </div>

      <div class="org-form-field">
        <label>
          <input type="checkbox" checked={{this.formData.is_shared}} {{on "change" (fn this.toggleFacility "is_shared")}} />
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
