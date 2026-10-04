import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { LinkTo } from "@ember/routing";
import { eq } from "discourse/truth-helpers";
import DesAddCarModal from "../components/des-add-car-modal";
import DesSuggestModelModal from "../components/des-suggest-model-modal";

export default <template>
  <div class="car-models-container">
    <div class="events-nav">
      <LinkTo class="btn btn-default" @route="events">📅 Events</LinkTo>
      <LinkTo class="btn btn-default" @route="organisations">🏢 Organisations</LinkTo>
      <LinkTo class="btn btn-default" @route="venues">📍 Venues</LinkTo>
      <LinkTo class="btn btn-primary" @route="car-models">🚗 Car Models</LinkTo>
    </div>

    <div class="manage-section-header">
      <h1>🚗 Car Models</h1>
    </div>

    {{!-- Quick Navigation --}}
    <div class="manufacturer-nav-grid">
      {{#each @controller.approvedManufacturers as |mfr|}}
        <a class="manufacturer-nav-card" href="#manufacturer-{{mfr.id}}">
          {{#if mfr.logo_url}}
            <img alt={{mfr.name}} class="manufacturer-nav-logo" src={{mfr.logo_url}} />
          {{else}}
            <div class="manufacturer-nav-placeholder">🏭</div>
          {{/if}}
          <span class="manufacturer-nav-name">{{mfr.name}}</span>
        </a>
      {{/each}}
    </div>

    {{#if @controller.currentUser}}
      {{#unless @controller.currentUser.admin}}
        <div class="des-admin-section">
          <div class="section-header">
            <div style="display:flex;gap:8px;">
              <button class="btn btn-default btn-small" {{on "click" @controller.toggleSuggestManufacturer}}>
                {{if @controller.showSuggestManufacturer "✕ Cancel" "➕ Suggest Manufacturer"}}
              </button>
              <button class="btn btn-default btn-small" {{on "click" (fn @controller.openSuggestModelModal null)}}>
                ➕ Suggest Model
              </button>
            </div>
          </div>

          {{#if @controller.showSuggestManufacturer}}
            <div class="add-model-form">
              <h4>Suggest a Manufacturer</h4>
              <p class="field-help">Your suggestion will be reviewed by an admin.</p>
              <div class="org-form-row">
                <div class="org-form-field">
                  <label>Manufacturer Name *</label>
                  <input placeholder="e.g. Associated RC" type="text" value={{@controller.newManufacturerName}} {{on "input" @controller.updateNewManufacturerName}} />
                </div>
              </div>
              <button class="btn btn-primary" {{on "click" @controller.suggestManufacturer}}>Submit Suggestion</button>
            </div>
          {{/if}}
        </div>
      {{/unless}}
    {{/if}}

    {{!-- Models by Manufacturer --}}
    {{#each @controller.model.models_by_manufacturer as |group|}}
      <div class="des-admin-section" id="manufacturer-{{group.manufacturer_id}}">
        <div class="section-header">
          <h2>
            {{#if group.manufacturer_logo_url}}
              <img alt={{group.manufacturer_name}} class="manufacturer-logo-heading" src={{group.manufacturer_logo_url}} />
            {{/if}}
            {{group.manufacturer_name}}
            {{#if (eq group.manufacturer_status "pending")}}
              <span class="pending-tag">⏳ Pending</span>
            {{/if}}
          </h2>
          {{#if @controller.currentUser}}
            {{#unless @controller.currentUser.admin}}
              <button class="btn btn-default btn-small" {{on "click" (fn @controller.openSuggestModelModal group)}}>
                ➕ Suggest Model
              </button>
            {{/unless}}
          {{/if}}
          {{#if @controller.currentUser.admin}}
            <button class="btn btn-primary btn-small" {{on "click" (fn @controller.startAddModel group.manufacturer_id group.manufacturer_name)}}>➕ Add Model</button>
          {{/if}}
        </div>

        {{#if (eq @controller.addingModelForManufacturerId group.manufacturer_id)}}
          <div class="add-model-form">
            <h4>Add Model for {{group.manufacturer_name}}</h4>
            <div class="org-form-row">
              <div class="org-form-field">
                <label>Name *</label>
                <input placeholder="e.g. B7.1" type="text" value={{@controller.newModelForm.name}} {{on "input" (fn @controller.updateNewModelField "name")}} />
              </div>
              <div class="org-form-field">
                <label>Year</label>
                <input placeholder="e.g. 2024" type="number" value={{@controller.newModelForm.year_released}} {{on "input" (fn @controller.updateNewModelField "year_released")}} />
              </div>
              <div class="org-form-field">
                <label>Driveline</label>
                <select {{on "change" (fn @controller.updateNewModelField "driveline")}}>
                  <option value="">Select...</option>
                  <option value="2WD">2WD</option>
                  <option value="4WD">4WD</option>
                  <option value="FWD">FWD</option>
                  <option value="Rear Motor">Rear Motor</option>
                </select>
              </div>
              <div class="org-form-field">
                <label>Scale</label>
                <select {{on "change" (fn @controller.updateNewModelField "scale")}}>
                  <option value="">Select...</option>
                  {{#each @controller.scales as |s|}}
                    <option value={{s}}>{{s}}</option>
                  {{/each}}
                </select>
              </div>
              <div class="org-form-field">
                <label>Chassis Type</label>
                <select {{on "change" (fn @controller.updateNewModelField "chassis_type")}}>
                  <option value="">Select...</option>
                  {{#each @controller.chassisTypes as |c|}}
                    <option value={{c}}>{{c}}</option>
                  {{/each}}
                </select>
              </div>
              <div class="org-form-field">
                <label>Power Type</label>
                <select {{on "change" (fn @controller.updateNewModelField "power_type")}}>
                  <option value="">Select...</option>
                  <option value="electric">Electric</option>
                  <option value="nitro">Nitro</option>
                  <option value="petrol">Petrol</option>
                  <option value="both">Both</option>
                </select>
              </div>
            </div>
            <div style="display:flex;gap:8px;margin-top:8px;">
              <button class="btn btn-primary" {{on "click" @controller.confirmAddModel}}>✅ Add Model</button>
              <button class="btn btn-default" {{on "click" @controller.cancelAddModel}}>✕ Cancel</button>
            </div>
          </div>
        {{/if}}

        <div class="models-grid">
          {{#each group.models as |model|}}
            <div class="model-card {{if (eq model.status 'pending') 'model-card--pending' ''}}">
              <div class="model-card-header">
                <strong>{{model.name}}</strong>
                {{#if (eq model.status "pending")}}
                  <span class="pending-tag">⏳ Pending</span>
                {{/if}}
              </div>
              <div class="model-card-meta">
                {{#if model.scale}}<span class="driveline-badge">📏 {{model.scale}}</span>{{/if}}
                {{#if model.chassis_type}}<span class="driveline-badge">🚗 {{model.chassis_type}}</span>{{/if}}
                {{#if model.driveline}}<span class="driveline-badge">⚙️ {{model.driveline}}</span>{{/if}}
                {{#if model.power_type}}<span class="driveline-badge">⚡ {{model.power_type}}</span>{{/if}}
                {{#if model.year_released}}<span class="driveline-badge">📅 {{model.year_released}}</span>{{/if}}
                {{#if model.created_by}}<span class="field-help">Suggested by {{model.created_by}}</span>{{/if}}
              </div>
              <div class="model-card-actions">
                {{#unless (eq model.status "pending")}}
                  {{#if @controller.currentUser}}
                    <button class="btn btn-primary btn-small" {{on "click" (fn @controller.addToGarage model)}}>🚗 Add to My Garage</button>
                  {{/if}}
                {{/unless}}
                {{#if @controller.currentUser.admin}}
                  {{#if (eq model.status "pending")}}
                    <button class="btn btn-success btn-small" {{on "click" (fn @controller.startApproveModel model)}}>✅ Approve</button>
                    <button class="btn btn-danger btn-small" {{on "click" (fn @controller.rejectModel model)}}>❌ Reject</button>
                  {{else}}
                    <button class="btn btn-default btn-small" {{on "click" (fn @controller.startEditModel model)}}>✏️ Edit</button>
                    <button class="btn btn-danger btn-small" {{on "click" (fn @controller.deleteModel model)}}>🗑 Delete</button>
                  {{/if}}
                {{/if}}
              </div>

              {{!-- Inline approve form --}}
              {{#if (eq @controller.approvingModelId model.id)}}
                <div class="add-model-form" style="margin-top:8px;">
                  <div class="org-form-row">
                    <div class="org-form-field">
                      <label>Year</label>
                      <input type="number" value={{@controller.approveModelForm.year_released}} {{on "input" (fn @controller.updateApproveField "year_released")}} />
                    </div>
                    <div class="org-form-field">
                      <label>Driveline</label>
                      <select {{on "change" (fn @controller.updateApproveField "driveline")}}>
                        <option value="">Select...</option>
                        <option value="2WD">2WD</option>
                        <option value="4WD">4WD</option>
                        <option value="FWD">FWD</option>
                        <option value="Rear Motor">Rear Motor</option>
                      </select>
                    </div>
                    <div class="org-form-field">
                      <label>Scale</label>
                      <select {{on "change" (fn @controller.updateApproveField "scale")}}>
                        <option value="">Select...</option>
                        {{#each @controller.scales as |s|}}
                          <option value={{s}}>{{s}}</option>
                        {{/each}}
                      </select>
                    </div>
                    <div class="org-form-field">
                      <label>Chassis Type</label>
                      <select {{on "change" (fn @controller.updateApproveField "chassis_type")}}>
                        <option value="">Select...</option>
                        {{#each @controller.chassisTypes as |c|}}
                          <option value={{c}}>{{c}}</option>
                        {{/each}}
                      </select>
                    </div>
                    <div class="org-form-field">
                      <label>Power Type</label>
                      <select {{on "change" (fn @controller.updateApproveField "power_type")}}>
                        <option value="">Select...</option>
                        <option selected={{eq @controller.approveModelForm.power_type "electric"}} value="electric">Electric</option>
                        <option selected={{eq @controller.approveModelForm.power_type "nitro"}} value="nitro">Nitro</option>
                        <option selected={{eq @controller.approveModelForm.power_type "petrol"}} value="petrol">Petrol</option>
                        <option selected={{eq @controller.approveModelForm.power_type "both"}} value="both">Both</option>
                      </select>
                    </div>
                  </div>
                  <div style="display:flex;gap:8px;margin-top:8px;">
                    <button class="btn btn-primary" {{on "click" @controller.confirmApproveModel}}>✅ Confirm</button>
                    <button class="btn btn-default" {{on "click" @controller.cancelApproveModel}}>✕ Cancel</button>
                  </div>
                </div>
              {{/if}}

              {{!-- Inline edit form --}}
              {{#if (eq @controller.editingModelId model.id)}}
                <div class="add-model-form" style="margin-top:8px;">
                  <div class="org-form-row">
                    <div class="org-form-field">
                      <label>Name</label>
                      <input type="text" value={{@controller.editModelForm.name}} {{on "input" (fn @controller.updateEditModelField "name")}} />
                    </div>
                    <div class="org-form-field">
                      <label>Year</label>
                      <input type="number" value={{@controller.editModelForm.year_released}} {{on "input" (fn @controller.updateEditModelField "year_released")}} />
                    </div>
                    <div class="org-form-field">
                      <label>Driveline</label>
                      <select {{on "change" (fn @controller.updateEditModelField "driveline")}}>
                        <option value="">Select...</option>
                        <option selected={{eq @controller.editModelForm.driveline "2WD"}} value="2WD">2WD</option>
                        <option selected={{eq @controller.editModelForm.driveline "4WD"}} value="4WD">4WD</option>
                        <option selected={{eq @controller.editModelForm.driveline "FWD"}} value="FWD">FWD</option>
                        <option selected={{eq @controller.editModelForm.driveline "Rear Motor"}} value="Rear Motor">Rear Motor</option>
                      </select>
                    </div>
                    <div class="org-form-field">
                      <label>Scale</label>
                      <select {{on "change" (fn @controller.updateEditModelField "scale")}}>
                        <option value="">Select...</option>
                        {{#each @controller.scales as |s|}}
                          <option selected={{eq @controller.editModelForm.scale s}} value={{s}}>{{s}}</option>
                        {{/each}}
                      </select>
                    </div>
                    <div class="org-form-field">
                      <label>Chassis Type</label>
                      <select {{on "change" (fn @controller.updateEditModelField "chassis_type")}}>
                        <option value="">Select...</option>
                        {{#each @controller.chassisTypes as |c|}}
                          <option selected={{eq @controller.editModelForm.chassis_type c}} value={{c}}>{{c}}</option>
                        {{/each}}
                      </select>
                    </div>
                    <div class="org-form-field">
                      <label>Power Type</label>
                      <select {{on "change" (fn @controller.updateEditModelField "power_type")}}>
                        <option value="">Select...</option>
                        <option selected={{eq @controller.editModelForm.power_type "electric"}} value="electric">Electric</option>
                        <option selected={{eq @controller.editModelForm.power_type "nitro"}} value="nitro">Nitro</option>
                        <option selected={{eq @controller.editModelForm.power_type "petrol"}} value="petrol">Petrol</option>
                        <option selected={{eq @controller.editModelForm.power_type "both"}} value="both">Both</option>
                      </select>
                    </div>
                  </div>
                  <div style="display:flex;gap:8px;margin-top:8px;">
                    <button class="btn btn-primary" {{on "click" @controller.saveEditModel}}>💾 Save</button>
                    <button class="btn btn-default" {{on "click" @controller.cancelEditModel}}>✕ Cancel</button>
                  </div>
                </div>
              {{/if}}
            </div>
          {{/each}}
        </div>
      </div>
    {{/each}}

    {{#if @controller.showAddCarModal}}
      <DesAddCarModal
        @manufacturerId={{@controller.addCarManufacturerId}}
        @modelId={{@controller.addCarModelId}}
        @onClose={{@controller.closeAddCarModal}}
        @onSave={{@controller.onCarAdded}}
      />
    {{/if}}

    {{#if @controller.showSuggestModelModal}}
      <DesSuggestModelModal
        @chassisTypes={{@controller.chassisTypes}}
        @manufacturers={{@controller.approvedManufacturers}}
        @onClose={{@controller.closeSuggestModelModal}}
        @onSave={{@controller.onModelSuggested}}
        @preselectedManufacturer={{@controller.suggestModelPreselectedManufacturer}}
        @scales={{@controller.scales}}
      />
    {{/if}}
  </div>
</template>
