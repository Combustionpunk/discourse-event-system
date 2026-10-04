import { concat, fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { LinkTo } from "@ember/routing";
import { eq } from "discourse/truth-helpers";
import DesAddCarModal from "../components/des-add-car-modal";
import transponderDisplay from "../helpers/transponder-display";

export default <template>
  <div class="garage-container">
    <div class="events-nav">
      <LinkTo class="btn btn-default" @route="my-organisations">🏢 My Organisations</LinkTo>
      <LinkTo class="btn btn-default" @route="racing-profile">🏎️ My Racing Profile</LinkTo>
      <LinkTo class="btn btn-default" @route="my-garage">🚗 My Garage</LinkTo>
      <LinkTo class="btn btn-default" @route="my-bookings">🎟️ My Bookings</LinkTo>
      <LinkTo class="btn btn-default" @route="my-memberships">🎫 My Memberships</LinkTo>
    </div>

    <div class="garage-header">
      <h1>🚗 My Garage</h1>
      <button class="btn btn-primary" {{on "click" @controller.toggleAddForm}}>
        {{if @controller.showAddForm "Cancel" "+ Add Car"}}
      </button>
    </div>

    {{#if @controller.showAddForm}}
      <DesAddCarModal
        @onClose={{@controller.toggleAddForm}}
        @onSave={{@controller.onCarAdded}}
      />
    {{/if}}

    {{#if @controller.model.cars.length}}
      <div class="garage-grid">
        {{#each @controller.model.cars as |car|}}
          <div class="garage-car-card {{if (eq @controller.editingCarId car.id) 'garage-car-card--editing'}}">
            {{#if (eq @controller.editingCarId car.id)}}
              <div class="garage-car-edit-form">
                <div class="org-form-field">
                  <label>Manufacturer</label>
                  <select {{on "change" @controller.editSelectManufacturer}}>
                    <option value="">Select...</option>
                    {{#each @controller.model.manufacturers as |mfr|}}
                      <option selected={{eq (concat mfr.id "") (concat @controller.editingCar.manufacturer_id "")}} value={{mfr.id}}>{{mfr.name}}</option>
                    {{/each}}
                  </select>
                </div>
                <div class="org-form-field">
                  <label>Model</label>
                  <select {{on "change" (fn @controller.updateEditCarField "car_model_id")}}>
                    <option value="">Select...</option>
                    {{#each @controller.editModels as |m|}}
                      <option selected={{eq (concat m.id "") (concat @controller.editingCar.car_model_id "")}} value={{m.id}}>{{m.name}}</option>
                    {{/each}}
                  </select>
                </div>
                <div class="org-form-field">
                  <label>Nickname</label>
                  <input type="text" value={{@controller.editingCar.friendly_name}} {{on "input" (fn @controller.updateEditCarField "friendly_name")}} />
                </div>
                <div class="org-form-field">
                  <label>Transponder</label>
                  <select {{on "change" @controller.setEditCarTransponderMode}}>
                    {{#each @controller.userTransponders as |t|}}
                      <option selected={{eq @controller.editingCar.transponder_number t.long_code}} value={{t.id}}>#{{t.shortcode}} — {{t.long_code}}{{#if t.notes}} ({{t.notes}}){{/if}}</option>
                    {{/each}}
                    <option selected={{eq @controller.editCarTransponderMode "new"}} value="new">✏️ Enter new code...</option>
                  </select>
                  {{#if (eq @controller.editCarTransponderMode "new")}}
                    <input placeholder="e.g. 1234567" style="margin-top: 6px;" type="text" value={{@controller.editCarTransponderNew}} {{on "input" @controller.updateEditCarTransponderNew}} {{on "blur" @controller.validateTransponderCode}} />
                    {{#if @controller.transponderError}}
                      <p class="field-help" style="color:var(--danger);margin:2px 0 0;">{{@controller.transponderError}}</p>
                    {{/if}}
                  {{/if}}
                </div>

                <div class="garage-car-actions">
                  <button class="btn btn-primary btn-small" {{on "click" @controller.saveEditCar}}>💾 Save</button>
                  <button class="btn btn-default btn-small" {{on "click" @controller.cancelEditCar}}>✕ Cancel</button>
                </div>
              </div>
            {{else}}
              <div class="garage-car-header">
                <span class="garage-car-icon">🚗</span>
                <div class="garage-car-title">
                  <strong>{{car.friendly_name}}</strong>
                  {{#if car.driveline}}
                    <span class="driveline-badge">{{car.driveline}}</span>
                  {{/if}}
                </div>
              </div>

              <div class="garage-car-body">
                {{#if car.manufacturer}}
                  <div class="garage-car-row">
                    <span class="garage-car-label">🏭 Manufacturer</span>
                    <span>{{car.manufacturer.name}}</span>
                  </div>
                {{/if}}
                {{#if car.model}}
                  <div class="garage-car-row">
                    <span class="garage-car-label">📋 Model</span>
                    <span>{{car.model.name}}
                      {{#if car.model.year_released}}({{car.model.year_released}}){{/if}}
                      {{#unless car.model_approved}}
                        <span class="pending-tag">pending</span>
                      {{/unless}}
                    </span>
                  </div>
                  {{#if car.model.scale}}
                    <div class="garage-car-row">
                      <span class="garage-car-label">📏 Scale</span>
                      <span>{{car.model.scale}}</span>
                    </div>
                  {{/if}}
                  {{#if car.model.chassis_type}}
                    <div class="garage-car-row">
                      <span class="garage-car-label">🏎️ Chassis</span>
                      <span>{{car.model.chassis_type}}</span>
                    </div>
                  {{/if}}
                {{else if car.custom_model_name}}
                  <div class="garage-car-row">
                    <span class="garage-car-label">📋 Model</span>
                    <span>{{car.custom_model_name}} <span class="pending-tag">pending</span></span>
                  </div>
                {{/if}}
                {{#if car.transponder_number}}
                  <div class="garage-car-row">
                    <span class="garage-car-label">📡 Transponder</span>
                    <span class="transponder-number">{{transponderDisplay car.transponder_number @controller.userTransponders}}</span>
                  </div>
                {{/if}}
              </div>

              <div class="garage-car-actions">
                <button class="btn btn-small btn-default" {{on "click" (fn @controller.editCar car)}}>
                  ✏️ Edit
                </button>
                <button class="btn btn-small btn-danger" {{on "click" (fn @controller.removeCar car.id)}}>
                  🗑 Remove
                </button>
              </div>
            {{/if}}
          </div>
        {{/each}}
      </div>
    {{else}}
      <div class="events-empty">
        <p>Your garage is empty! Add your first car to get started.</p>
      </div>
    {{/if}}
  </div>
</template>
