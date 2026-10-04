import { concat, fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { eq } from "discourse/truth-helpers";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";

const DRIVELINES = ["2WD", "4WD", "FWD", "Rear Motor"];
const POWER_TYPES = ["electric", "nitro", "petrol", "both"];

const PowerTypeOptions = <template>
  <option value="">{{i18n "discourse_event_system.car_models.select"}}</option>
  {{#each POWER_TYPES as |powerType|}}
    <option selected={{eq @selected powerType}} value={{powerType}}>
      {{i18n
        (concat "discourse_event_system.car_models.power_types." powerType)
      }}
    </option>
  {{/each}}
</template>;

const ListOptions = <template>
  <option value="">{{i18n "discourse_event_system.car_models.select"}}</option>
  {{#each @values as |value|}}
    <option selected={{eq @selected value}} value={{value}}>{{value}}</option>
  {{/each}}
</template>;

export const ModelSpecFields = <template>
  <div class="org-form-field">
    <label>{{i18n "discourse_event_system.car_models.fields.year"}}</label>
    <input
      placeholder={{i18n
        "discourse_event_system.car_models.fields.year_placeholder"
      }}
      type="number"
      value={{@form.year_released}}
      {{on "input" (fn @onChange "year_released")}}
    />
  </div>
  <div class="org-form-field">
    <label>{{i18n "discourse_event_system.car_models.fields.driveline"}}</label>
    <select {{on "change" (fn @onChange "driveline")}}>
      <ListOptions @selected={{@form.driveline}} @values={{DRIVELINES}} />
    </select>
  </div>
  <div class="org-form-field">
    <label>{{i18n "discourse_event_system.car_models.fields.scale"}}</label>
    <select {{on "change" (fn @onChange "scale")}}>
      <ListOptions @selected={{@form.scale}} @values={{@scales}} />
    </select>
  </div>
  <div class="org-form-field">
    <label>{{i18n
        "discourse_event_system.car_models.fields.chassis_type"
      }}</label>
    <select {{on "change" (fn @onChange "chassis_type")}}>
      <ListOptions @selected={{@form.chassis_type}} @values={{@chassisTypes}} />
    </select>
  </div>
  <div class="org-form-field">
    <label>{{i18n
        "discourse_event_system.car_models.fields.power_type"
      }}</label>
    <select {{on "change" (fn @onChange "power_type")}}>
      <PowerTypeOptions @selected={{@form.power_type}} />
    </select>
  </div>
</template>;

export const FormActions = <template>
  <div class="des-model-form__actions">
    <DButton
      class="btn-primary"
      @action={{@onConfirm}}
      @icon="check"
      @label={{@confirmLabel}}
    />
    <DButton
      @action={{@onCancel}}
      @label="discourse_event_system.car_models.cancel"
    />
  </div>
</template>;
