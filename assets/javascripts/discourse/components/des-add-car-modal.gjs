import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { on } from "@ember/modifier";
import { fn, concat } from "@ember/helper";
import { eq } from "truth-helpers";

export default class DesAddCarModal extends Component {
  @tracked newCar = {
    manufacturer_id: "", car_model_id: "", driveline: "",
    transponder_number: "", friendly_name: ""
  };
  @tracked availableModels = [];
  @tracked selectedModel = null;
  @tracked manufacturers = [];
  @tracked userTransponders = [];
  @tracked transponderMode = "registry";
  @tracked newTransponderCode = "";
  @tracked showSuggestModel = false;
  @tracked suggestModelName = "";
  @tracked suggestModelYear = "";
  @tracked suggestModelDriveline = "";
  @tracked scales = [];
  @tracked chassisTypes = [];
  @tracked suggestModelScale = "";
  @tracked suggestModelChassisType = "";
  @tracked isSaving = false;
  drivelines = ["2WD", "4WD", "FWD", "Rear Motor"];

  constructor() {
    super(...arguments);
    this.loadData();
  }

  async loadData() {
    try {
      const [garageResp, transponderResp, scalesResp, chassisResp] = await Promise.all([
        ajax("/des/garage.json"),
        ajax("/des/transponders.json"),
        ajax("/des/admin/scales.json"),
        ajax("/des/admin/chassis-types.json"),
      ]);
      this.manufacturers = garageResp.manufacturers || [];
      this.userTransponders = transponderResp.transponders || [];
      this.scales = scalesResp.scales.map(s => s.name);
      this.chassisTypes = chassisResp.chassis_types.map(c => c.name);

      if (this.args.manufacturerId) {
        this.newCar = { ...this.newCar, manufacturer_id: String(this.args.manufacturerId) };
        await this.loadModels(this.args.manufacturerId);
      }
      if (this.args.modelId && this.availableModels.length) {
        const model = this.availableModels.find(m => String(m.id) === String(this.args.modelId));
        if (model) {
          this.selectedModel = model;
          this.newCar = { ...this.newCar, car_model_id: String(this.args.modelId), driveline: model.driveline || "" };
        }
      }

      if (this.userTransponders.length) {
        this.newCar = { ...this.newCar, transponder_number: this.userTransponders[0].long_code };
      }
    } catch {
      // ignore load errors
    }
  }

  async loadModels(manufacturerId) {
    try {
      const response = await ajax("/des/garage/models.json", { data: { manufacturer_id: manufacturerId } });
      this.availableModels = response.models || [];
    } catch {
      this.availableModels = [];
    }
  }

  @action
  stopPropagation(e) {
    e.stopPropagation();
  }

  @action
  async selectManufacturer(e) {
    const manufacturerId = e.target.value;
    this.newCar = { ...this.newCar, manufacturer_id: manufacturerId, car_model_id: "" };
    this.selectedModel = null;
    this.showSuggestModel = false;
    if (manufacturerId) {
      await this.loadModels(manufacturerId);
    } else {
      this.availableModels = [];
    }
  }

  @action
  selectModel(e) {
    const modelId = e.target.value;
    if (modelId === "suggest") {
      this.showSuggestModel = true;
      this.selectedModel = null;
      this.newCar = { ...this.newCar, car_model_id: "" };
      return;
    }
    this.showSuggestModel = false;
    this.newCar = { ...this.newCar, car_model_id: modelId };
    this.selectedModel = this.availableModels.find(m => String(m.id) === modelId) || null;
    if (this.selectedModel) {
      this.newCar = { ...this.newCar, driveline: this.selectedModel.driveline || "" };
    }
  }

  @action
  updateField(field, e) {
    this.newCar = { ...this.newCar, [field]: e.target.value };
  }

  @action
  setTransponderMode(e) {
    const value = e.target.value;
    this.transponderMode = value === "new" ? "new" : "registry";
    if (value !== "new") {
      const t = this.userTransponders.find(tr => tr.id === parseInt(value));
      if (t) this.newCar = { ...this.newCar, transponder_number: t.long_code };
    } else {
      this.newCar = { ...this.newCar, transponder_number: "" };
    }
  }

  @action
  updateNewTransponderCode(e) {
    this.newTransponderCode = e.target.value;
    this.newCar = { ...this.newCar, transponder_number: e.target.value };
  }

  @action
  updateSuggestField(field, e) {
    this[field] = e.target.value;
  }

  @action
  async save() {
    this.isSaving = true;
    try {
      // Handle suggest model flow
      if (this.showSuggestModel && this.suggestModelName.trim()) {
        const modelResponse = await ajax("/des/garage/suggest-model.json", {
          type: "POST",
          data: {
            manufacturer_id: this.newCar.manufacturer_id,
            name: this.suggestModelName,
            year_released: this.suggestModelYear,
            driveline: this.suggestModelDriveline,
            scale: this.suggestModelScale,
            chassis_type: this.suggestModelChassisType,
          },
        });
        this.newCar = { ...this.newCar, car_model_id: modelResponse.id, driveline: this.suggestModelDriveline };
      }

      if (!this.newCar.car_model_id) {
        alert("Please select a car model");
        this.isSaving = false;
        return;
      }

      // Handle new transponder
      if (this.transponderMode === "new" && this.newTransponderCode.trim()) {
        const exists = this.userTransponders.find(t => t.long_code === this.newTransponderCode.trim());
        if (!exists) {
          const nextShortcode = this.userTransponders.length > 0
            ? Math.max(...this.userTransponders.map(t => t.shortcode)) + 1 : 1;
          const doSave = window.confirm(`Save ${this.newTransponderCode.trim()} as transponder #${nextShortcode} in your racing profile?`);
          if (doSave) {
            try {
              await ajax("/des/transponders.json", {
                type: "POST",
                data: { long_code: this.newTransponderCode.trim() }
              });
            } catch {
              // continue even if transponder save fails
            }
          }
        }
      }

      await ajax("/des/garage.json", {
        type: "POST",
        data: { car: this.newCar }
      });

      this.args.onSave?.();
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
          <h2>🚗 Add Car to Garage</h2>
          <button class="btn btn-flat des-modal-close" {{on "click" @onClose}}>✕</button>
        </div>
        <div class="des-modal-body">
          <div class="org-form-row">
            <div class="org-form-field">
              <label>Friendly Name</label>
              <input type="text" placeholder="e.g. Blue Bomber" value={{this.newCar.friendly_name}} {{on "input" (fn this.updateField "friendly_name")}} />
            </div>
            <div class="org-form-field">
              <label>Transponder</label>
              <select {{on "change" this.setTransponderMode}}>
                {{#each this.userTransponders as |t|}}
                  <option value={{t.id}} selected={{eq this.newCar.transponder_number t.long_code}}>#{{t.shortcode}} — {{t.long_code}}{{#if t.notes}} ({{t.notes}}){{/if}}</option>
                {{/each}}
                <option value="new">✏️ Enter new code...</option>
              </select>
              {{#if (eq this.transponderMode "new")}}
                <input type="text" placeholder="e.g. 7456985" value={{this.newTransponderCode}} {{on "input" this.updateNewTransponderCode}} style="margin-top:6px;" />
              {{/if}}
            </div>
          </div>

          <div class="org-form-row">
            <div class="org-form-field">
              <label>Manufacturer *</label>
              <select {{on "change" this.selectManufacturer}}>
                <option value="">Select manufacturer...</option>
                {{#each this.manufacturers as |mfr|}}
                  <option value={{mfr.id}} selected={{eq (concat this.newCar.manufacturer_id "") (concat mfr.id "")}}>{{mfr.name}}</option>
                {{/each}}
              </select>
            </div>
            <div class="org-form-field">
              <label>Model *</label>
              <select {{on "change" this.selectModel}} disabled={{eq this.newCar.manufacturer_id ""}}>
                <option value="">Select model...</option>
                {{#each this.availableModels as |m|}}
                  <option value={{m.id}} selected={{eq (concat this.newCar.car_model_id "") (concat m.id "")}}>
                    {{m.name}}{{#if m.year_released}} ({{m.year_released}}){{/if}}
                  </option>
                {{/each}}
                <option value="suggest">+ Suggest unlisted model</option>
              </select>
            </div>
          </div>

          {{#if this.selectedModel}}
            <div class="org-form-field">
              <label>Driveline</label>
              <div class="driveline-readonly">
                <span class="driveline-badge">{{this.selectedModel.driveline}}</span>
                <span class="field-help">Set by manufacturer specification</span>
              </div>
            </div>
          {{/if}}

          {{#if this.showSuggestModel}}
            <div class="add-model-form" style="margin-top:12px;">
              <h4>Suggest a Model</h4>
              <p class="field-help">Your suggestion will be reviewed by an admin. You can still add your car now.</p>
              <div class="org-form-row">
                <div class="org-form-field">
                  <label>Model Name *</label>
                  <input type="text" placeholder="e.g. RC10B7" value={{this.suggestModelName}} {{on "input" (fn this.updateSuggestField "suggestModelName")}} />
                </div>
                <div class="org-form-field">
                  <label>Year</label>
                  <input type="number" placeholder="e.g. 1987" value={{this.suggestModelYear}} {{on "input" (fn this.updateSuggestField "suggestModelYear")}} />
                </div>
              </div>
              <div class="org-form-row">
                <div class="org-form-field">
                  <label>Driveline</label>
                  <select {{on "change" (fn this.updateSuggestField "suggestModelDriveline")}}>
                    <option value="">Select...</option>
                    {{#each this.drivelines as |d|}}
                      <option value={{d}}>{{d}}</option>
                    {{/each}}
                  </select>
                </div>
                <div class="org-form-field">
                  <label>Scale</label>
                  <select {{on "change" (fn this.updateSuggestField "suggestModelScale")}}>
                    <option value="">Select...</option>
                    {{#each this.scales as |s|}}
                      <option value={{s}}>{{s}}</option>
                    {{/each}}
                  </select>
                </div>
                <div class="org-form-field">
                  <label>Chassis Type</label>
                  <select {{on "change" (fn this.updateSuggestField "suggestModelChassisType")}}>
                    <option value="">Select...</option>
                    {{#each this.chassisTypes as |c|}}
                      <option value={{c}}>{{c}}</option>
                    {{/each}}
                  </select>
                </div>
              </div>
            </div>
          {{/if}}

          <div class="des-modal-actions">
            <button class="btn btn-primary" disabled={{this.isSaving}} {{on "click" this.save}}>
              {{if this.isSaving "Saving..." "🚗 Add to Garage"}}
            </button>
            <button class="btn btn-default" {{on "click" @onClose}}>Cancel</button>
          </div>
        </div>
      </div>
    </div>
  </template>
}
