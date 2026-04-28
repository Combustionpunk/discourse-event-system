import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { on } from "@ember/modifier";
import { concat, fn } from "@ember/helper";
import { eq } from "truth-helpers";

export default class DesClassTypeForm extends Component {
  @tracked formData = {
    name: "", track_environment: "", scale: "",
    chassis_types: [], drivelines: [],
    min_year: "", max_year: "", manufacturer: "",
    model_id: "", min_age: "", max_age: ""
  };
  @tracked scales = [];
  @tracked chassisTypes = [];

  drivelines = ["2WD", "4WD", "FWD", "Rear Motor"];

  get yearOptions() {
    const current = new Date().getFullYear();
    const years = [];
    for (let y = current; y >= 1970; y--) years.push(y);
    return years;
  }

  get ageOptions() {
    return [10, 14, 16, 18, 30, 40, 45];
  }

  constructor() {
    super(...arguments);
    if (this.args.classType) {
      const ct = this.args.classType;
      this.formData = {
        name: ct.name || "",
        track_environment: ct.track_environment || "",
        scale: ct.scale || "",
        chassis_types: ct.chassis_types || [],
        drivelines: ct.drivelines || [],
        min_year: ct.min_year || "",
        max_year: ct.max_year || "",
        manufacturer: ct.manufacturer || "",
        model_id: ct.model_id || "",
        min_age: ct.min_age || "",
        max_age: ct.max_age || ""
      };
    }
    this.loadLists();
  }

  async loadLists() {
    try {
      const [scalesResp, chassisResp] = await Promise.all([
        ajax("/des/admin/scales.json"),
        ajax("/des/admin/chassis-types.json"),
      ]);
      this.scales = scalesResp.scales.map(s => s.name);
      this.chassisTypes = chassisResp.chassis_types.map(c => c.name);
    } catch {
      // fall back to empty
    }
  }

  get filteredModels() {
    if (!this.formData.manufacturer) return this.args.models || [];
    return (this.args.models || []).filter(m => m.manufacturer === this.formData.manufacturer);
  }

  @action
  updateField(field, e) {
    const newData = { ...this.formData, [field]: e.target.value };
    if (field === 'manufacturer') {
      newData.model_id = "";
    }
    this.formData = newData;
  }

  @action
  updateMultiField(field, event) {
    const selected = Array.from(event.target.selectedOptions).map(o => o.value);
    this.formData = { ...this.formData, [field]: selected };
  }

  @action
  async save() {
    if (!this.formData.name.trim()) {
      alert("Please enter a class type name");
      return;
    }
    try {
      await this.args.onSave(this.formData);
      this.formData = {
        name: "", track_environment: "", scale: "",
        chassis_types: [], drivelines: [],
        min_year: "", max_year: "", manufacturer: "",
        model_id: "", min_age: "", max_age: ""
      };
    } catch (error) {
      popupAjaxError(error);
    }
  }

  <template>
    <div class="des-class-type-form">
      <div class="org-form-row">
        <div class="org-form-field">
          <label>Name *</label>
          <input type="text" value={{this.formData.name}} placeholder="e.g. 2WD Buggy" {{on "input" (fn this.updateField "name")}} />
        </div>
        <div class="org-form-field">
          <label>Track Environment</label>
          <select {{on "change" (fn this.updateField "track_environment")}}>
            <option value="">Any</option>
            <option value="onroad" selected={{eq this.formData.track_environment "onroad"}}>🛣️ On-Road</option>
            <option value="offroad" selected={{eq this.formData.track_environment "offroad"}}>🌿 Off-Road</option>
          </select>
        </div>
        <div class="org-form-field">
          <label>Scale</label>
          <select {{on "change" (fn this.updateField "scale")}}>
            <option value="">Any Scale</option>
            {{#each this.scales as |s|}}
              <option value={{s}} selected={{eq this.formData.scale s}}>{{s}}</option>
            {{/each}}
          </select>
        </div>
      </div>

      <div class="org-form-row">
        <div class="org-form-field">
          <label>Chassis Types</label>
          <select multiple {{on "change" (fn this.updateMultiField "chassis_types")}}>
            {{#each this.chassisTypes as |c|}}
              <option value={{c}}>{{c}}</option>
            {{/each}}
          </select>
          <p class="field-help">Ctrl/Cmd to multi-select. Empty = any.</p>
        </div>
        <div class="org-form-field">
          <label>Drivelines</label>
          <select multiple {{on "change" (fn this.updateMultiField "drivelines")}}>
            {{#each this.drivelines as |d|}}
              <option value={{d}}>{{d}}</option>
            {{/each}}
          </select>
          <p class="field-help">Ctrl/Cmd to multi-select. Empty = any.</p>
        </div>
      </div>

      <div class="org-form-row">
        <div class="org-form-field">
          <label>Min Year</label>
          <select {{on "change" (fn this.updateField "min_year")}}>
            <option value="">Any</option>
            {{#each this.yearOptions as |y|}}
              <option value={{y}} selected={{eq (concat this.formData.min_year "") (concat y "")}}>{{y}}</option>
            {{/each}}
          </select>
        </div>
        <div class="org-form-field">
          <label>Max Year</label>
          <select {{on "change" (fn this.updateField "max_year")}}>
            <option value="">Any</option>
            {{#each this.yearOptions as |y|}}
              <option value={{y}} selected={{eq (concat this.formData.max_year "") (concat y "")}}>{{y}}</option>
            {{/each}}
          </select>
        </div>
      </div>

      <div class="org-form-row">
        <div class="org-form-field">
          <label>Manufacturer</label>
          <select {{on "change" (fn this.updateField "manufacturer")}}>
            <option value="">Any</option>
            {{#each @manufacturers as |mfr|}}
              <option value={{mfr.name}} selected={{eq this.formData.manufacturer mfr.name}}>{{mfr.name}}</option>
            {{/each}}
          </select>
        </div>
        <div class="org-form-field">
          <label>Model</label>
          <select {{on "change" (fn this.updateField "model_id")}}>
            <option value="">Any</option>
            {{#each this.filteredModels as |m|}}
              <option value={{m.id}} selected={{eq (concat this.formData.model_id "") (concat m.id "")}}>{{m.manufacturer}} {{m.name}}</option>
            {{/each}}
          </select>
        </div>
      </div>

      <h4>Driver Eligibility</h4>
      <div class="org-form-row">
        <div class="org-form-field">
          <label>Min Age</label>
          <select {{on "change" (fn this.updateField "min_age")}}>
            <option value="">Any</option>
            {{#each this.ageOptions as |a|}}
              <option value={{a}} selected={{eq (concat this.formData.min_age "") (concat a "")}}>{{a}}</option>
            {{/each}}
          </select>
        </div>
        <div class="org-form-field">
          <label>Max Age</label>
          <select {{on "change" (fn this.updateField "max_age")}}>
            <option value="">Any</option>
            {{#each this.ageOptions as |a|}}
              <option value={{a}} selected={{eq (concat this.formData.max_age "") (concat a "")}}>{{a}}</option>
            {{/each}}
          </select>
        </div>
      </div>

      <button class="btn btn-primary" {{on "click" this.save}}>
        {{#if @saveLabel}}{{@saveLabel}}{{else}}✅ Save Class Type{{/if}}
      </button>
      {{#if @onCancel}}
        <button class="btn btn-default" style="margin-left: 8px;" {{on "click" @onCancel}}>✕ Cancel</button>
      {{/if}}
    </div>
  </template>
}
