import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { i18n } from "discourse-i18n";
import { FormActions, ModelSpecFields } from "./des-car-model-form-fields";
import DesLogoUploader from "./des-logo-uploader";

export default class DesCarModelEditForm extends Component {
  @tracked
  form = {
    name: this.args.model.name,
    year_released: this.args.model.year_released || "",
    driveline: this.args.model.driveline || "",
    scale: this.args.model.scale || "",
    chassis_type: this.args.model.chassis_type || "",
    power_type: this.args.model.power_type || "",
    box_art_upload_id: this.args.model.box_art_upload_id || null,
    box_art_url: this.args.model.box_art_url || null,
  };

  @action
  updateField(field, event) {
    this.form = { ...this.form, [field]: event.target.value };
  }

  @action
  boxArtUploaded(upload) {
    this.form = {
      ...this.form,
      box_art_upload_id: upload.id,
      box_art_url: upload.url,
    };
  }

  @action
  removeBoxArt() {
    this.form = { ...this.form, box_art_upload_id: null, box_art_url: null };
  }

  @action
  async save() {
    const form = this.form;
    try {
      await ajax(`/des/admin/models/${this.args.model.id}.json`, {
        type: "PUT",
        data: {
          name: form.name,
          year_released: form.year_released,
          driveline: form.driveline,
          scale: form.scale,
          chassis_type: form.chassis_type,
          power_type: form.power_type,
          // Blank clears the box art server-side.
          box_art_upload_id: form.box_art_upload_id || "",
        },
      });
      this.args.onSaved?.();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  <template>
    <div class="add-model-form des-model-edit-form">
      <div class="org-form-row">
        <div class="org-form-field">
          <label>{{i18n "discourse_event_system.car_models.fields.name"}}</label>
          <input
            type="text"
            value={{this.form.name}}
            {{on "input" (fn this.updateField "name")}}
          />
        </div>
        <ModelSpecFields
          @chassisTypes={{@chassisTypes}}
          @form={{this.form}}
          @onChange={{this.updateField}}
          @scales={{@scales}}
        />
        <div class="org-form-field">
          <label>{{i18n
              "discourse_event_system.car_models.box_art.label"
            }}</label>
          <DesLogoUploader
            @changeLabel={{i18n
              "discourse_event_system.car_models.box_art.change"
            }}
            @helpText={{i18n "discourse_event_system.car_models.box_art.help"}}
            @logoUrl={{this.form.box_art_url}}
            @onRemove={{this.removeBoxArt}}
            @onUpload={{this.boxArtUploaded}}
            @previewAlt={{i18n
              "discourse_event_system.car_models.box_art.label"
            }}
            @removeLabel={{i18n
              "discourse_event_system.car_models.box_art.remove"
            }}
            @uploadLabel={{i18n
              "discourse_event_system.car_models.box_art.upload"
            }}
          />
        </div>
      </div>
      <FormActions
        @confirmLabel="discourse_event_system.car_models.save"
        @onCancel={{@onCancel}}
        @onConfirm={{this.save}}
      />
    </div>
  </template>
}
