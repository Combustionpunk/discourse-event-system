import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { on } from "@ember/modifier";
import { fn, concat } from "@ember/helper";
import { eq } from "truth-helpers";

export default class DesSuggestModelModal extends Component {
  @tracked manufacturerId = "";
  @tracked name = "";
  @tracked yearReleased = "";
  @tracked driveline = "";
  @tracked scale = "";
  @tracked chassisType = "";
  @tracked powerType = "";
  @tracked isSaving = false;
  @tracked successMessage = "";

  drivelines = ["2WD", "4WD", "FWD", "Rear Motor"];
  powerTypes = ["electric", "nitro", "petrol", "both"];

  constructor() {
    super(...arguments);
    if (this.args.preselectedManufacturer) {
      this.manufacturerId = String(this.args.preselectedManufacturer.manufacturer_id || this.args.preselectedManufacturer.id || "");
    }
  }

  @action
  stopPropagation(e) {
    e.stopPropagation();
  }

  @action
  updateField(field, e) {
    this[field] = e.target.value;
  }

  @action
  async submit() {
    if (!this.name.trim() || !this.manufacturerId) return;
    this.isSaving = true;
    this.successMessage = "";
    try {
      await ajax("/des/garage/suggest-model.json", {
        type: "POST",
        data: {
          manufacturer_id: this.manufacturerId,
          name: this.name.trim(),
          year_released: this.yearReleased || undefined,
          driveline: this.driveline || undefined,
          scale: this.scale || undefined,
          chassis_type: this.chassisType || undefined,
        },
      });
      this.successMessage = "Model suggestion submitted for review!";
      setTimeout(() => this.args.onSave?.(), 1500);
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.isSaving = false;
    }
  }

  <template>
    <div class="des-modal-overlay" {{on "click" @onClose}}>
      <div class="des-modal" role="dialog" {{on "click" this.stopPropagation}}>
        <div class="des-modal-header">
          <h2>➕ Suggest a Model</h2>
          <button class="btn btn-flat des-modal-close" {{on "click" @onClose}}>✕</button>
        </div>
        <div class="des-modal-body">
          {{#if this.successMessage}}
            <div class="des-success-message">✅ {{this.successMessage}}</div>
          {{else}}
            <p class="field-help">Your suggestion will be reviewed by an admin.</p>

            <div class="org-form-row">
              <div class="org-form-field">
                <label>Manufacturer *</label>
                <select {{on "change" (fn this.updateField "manufacturerId")}}>
                  <option value="">Select manufacturer...</option>
                  {{#each @manufacturers as |mfr|}}
                    <option value={{mfr.id}} selected={{eq this.manufacturerId (concat mfr.id "")}}>{{mfr.name}}</option>
                  {{/each}}
                </select>
              </div>
              <div class="org-form-field">
                <label>Model name *</label>
                <input type="text" placeholder="e.g. RC10B7" value={{this.name}} {{on "input" (fn this.updateField "name")}} />
              </div>
            </div>

            <div class="org-form-row">
              <div class="org-form-field">
                <label>Year</label>
                <input type="number" placeholder="e.g. 2024" value={{this.yearReleased}} {{on "input" (fn this.updateField "yearReleased")}} />
              </div>
              <div class="org-form-field">
                <label>Driveline</label>
                <select {{on "change" (fn this.updateField "driveline")}}>
                  <option value="">Select...</option>
                  {{#each this.drivelines as |d|}}
                    <option value={{d}}>{{d}}</option>
                  {{/each}}
                </select>
              </div>
            </div>

            <div class="org-form-row">
              <div class="org-form-field">
                <label>Scale</label>
                <select {{on "change" (fn this.updateField "scale")}}>
                  <option value="">Select...</option>
                  {{#each @scales as |s|}}
                    <option value={{s}}>{{s}}</option>
                  {{/each}}
                </select>
              </div>
              <div class="org-form-field">
                <label>Chassis type</label>
                <select {{on "change" (fn this.updateField "chassisType")}}>
                  <option value="">Select...</option>
                  {{#each @chassisTypes as |c|}}
                    <option value={{c}}>{{c}}</option>
                  {{/each}}
                </select>
              </div>
            </div>

            <div class="org-form-row">
              <div class="org-form-field">
                <label>Power type</label>
                <select {{on "change" (fn this.updateField "powerType")}}>
                  <option value="">Select...</option>
                  {{#each this.powerTypes as |p|}}
                    <option value={{p}}>{{p}}</option>
                  {{/each}}
                </select>
              </div>
            </div>

            <div class="des-modal-actions">
              <button class="btn btn-primary" disabled={{this.isSaving}} {{on "click" this.submit}}>
                {{if this.isSaving "Submitting..." "➕ Submit Suggestion"}}
              </button>
              <button class="btn btn-default" {{on "click" @onClose}}>Cancel</button>
            </div>
          {{/if}}
        </div>
      </div>
    </div>
  </template>
}
