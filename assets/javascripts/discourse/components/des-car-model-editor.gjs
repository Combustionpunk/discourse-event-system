import Component from "@glimmer/component";
import { concat } from "@ember/helper";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { modifier } from "ember-modifier";
import Form from "discourse/components/form";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";
import { DRIVELINES, POWER_TYPES } from "./des-car-model-form-fields";

// Esc should close whatever overlay is on top, not the form underneath it.
const OVERLAY_SELECTOR = ".d-modal, .dialog-container, .mfp-wrap, .fk-d-menu";

export default class DesCarModelEditor extends Component {
  @service dialog;

  formApi = null;

  formData = {
    name: this.args.model.name,
    manufacturer_id: this.args.model.manufacturer_id,
    year_released: this.args.model.year_released,
    scale: this.args.model.scale,
    chassis_type: this.args.model.chassis_type,
    driveline: this.args.model.driveline,
    power_type: this.args.model.power_type,
    box_art_url: this.args.model.box_art_full_url,
    box_art_upload_id: this.args.model.box_art_upload_id,
  };

  guardPage = modifier(() => {
    const onKeydown = (event) => {
      if (
        event.key === "Escape" &&
        !event.defaultPrevented &&
        !document.querySelector(OVERLAY_SELECTOR) &&
        !event.target.closest?.(OVERLAY_SELECTOR)
      ) {
        event.preventDefault();
        this.cancel();
      }
    };
    const onBeforeUnload = (event) => {
      if (this.formApi?.isDirty) {
        event.preventDefault();
      }
    };

    document.addEventListener("keydown", onKeydown);
    window.addEventListener("beforeunload", onBeforeUnload);

    return () => {
      document.removeEventListener("keydown", onKeydown);
      window.removeEventListener("beforeunload", onBeforeUnload);
    };
  });

  @action
  registerApi(api) {
    this.formApi = api;
  }

  @action
  setBoxArt(upload, { set }) {
    set("box_art_url", upload?.url ?? null);
    set("box_art_upload_id", upload?.id ?? null);
  }

  @action
  async cancel() {
    if (this.formApi?.isDirty) {
      const confirmed = await this.dialog.yesNoConfirm({
        message: i18n("discourse_event_system.car_model_detail.edit.discard"),
      });
      if (!confirmed) {
        return;
      }
    }
    this.args.onCancel();
  }

  @action
  async save(data) {
    try {
      await ajax(`/des/admin/models/${this.args.model.id}.json`, {
        type: "PUT",
        data: {
          name: data.name,
          manufacturer_id: data.manufacturer_id,
          year_released: data.year_released,
          scale: data.scale,
          chassis_type: data.chassis_type,
          driveline: data.driveline,
          power_type: data.power_type,
          // Blank clears the box art server-side.
          box_art_upload_id: data.box_art_upload_id || "",
        },
      });
      this.args.onSaved();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  <template>
    <div class="des-car-model-editor" {{this.guardPage}}>
      <Form
        @data={{this.formData}}
        @onRegisterApi={{this.registerApi}}
        @onSubmit={{this.save}}
        as |form|
      >
        <div class="des-car-model-editor__layout">
          <div class="des-car-model-editor__art">
            <form.Field
              @format="full"
              @name="box_art_url"
              @onSet={{this.setBoxArt}}
              @title={{i18n
                "discourse_event_system.car_model_detail.edit.box_art"
              }}
              @type="image"
              as |field|
            >
              <field.Control @type="composer" />
            </form.Field>
            <p class="des-car-model-editor__help">
              {{i18n "discourse_event_system.car_models.box_art.help"}}
            </p>
            <DButton
              class="btn-default btn-small des-car-model-editor__fetch-url"
              @disabled={{true}}
              @icon="link"
              @label="discourse_event_system.car_model_detail.edit.fetch_from_url"
              @title="discourse_event_system.car_model_detail.edit.fetch_from_url_unavailable"
            />
          </div>

          <div class="des-car-model-editor__fields">
            <form.Field
              @format="full"
              @name="name"
              @title={{i18n "discourse_event_system.car_models.fields.name"}}
              @type="input"
              @validation="required|length:1,100"
              as |field|
            >
              <field.Control />
            </form.Field>

            <form.Field
              @format="full"
              @name="manufacturer_id"
              @title={{i18n
                "discourse_event_system.car_model_detail.edit.manufacturer"
              }}
              @type="select"
              @validation="required"
              as |field|
            >
              <field.Control as |select|>
                {{#each @manufacturers as |manufacturer|}}
                  <select.Option @value={{manufacturer.id}}>
                    {{manufacturer.name}}
                  </select.Option>
                {{/each}}
              </field.Control>
            </form.Field>

            <form.Field
              @format="full"
              @name="year_released"
              @title={{i18n "discourse_event_system.car_models.fields.year"}}
              @type="input-number"
              @validation="integer|between:1950,2100"
              as |field|
            >
              <field.Control
                placeholder={{i18n
                  "discourse_event_system.car_models.fields.year_placeholder"
                }}
              />
            </form.Field>

            <form.Field
              @format="full"
              @name="scale"
              @title={{i18n "discourse_event_system.car_models.fields.scale"}}
              @type="select"
              as |field|
            >
              <field.Control as |select|>
                {{#each @scales as |scale|}}
                  <select.Option @value={{scale}}>{{scale}}</select.Option>
                {{/each}}
              </field.Control>
            </form.Field>

            <form.Field
              @format="full"
              @name="chassis_type"
              @title={{i18n
                "discourse_event_system.car_models.fields.chassis_type"
              }}
              @type="select"
              as |field|
            >
              <field.Control as |select|>
                {{#each @chassisTypes as |chassisType|}}
                  <select.Option @value={{chassisType}}>
                    {{chassisType}}
                  </select.Option>
                {{/each}}
              </field.Control>
            </form.Field>

            <form.Field
              @format="full"
              @name="driveline"
              @title={{i18n
                "discourse_event_system.car_models.fields.driveline"
              }}
              @type="select"
              as |field|
            >
              <field.Control as |select|>
                {{#each DRIVELINES as |driveline|}}
                  <select.Option @value={{driveline}}>
                    {{driveline}}
                  </select.Option>
                {{/each}}
              </field.Control>
            </form.Field>

            <form.Field
              @format="full"
              @name="power_type"
              @title={{i18n
                "discourse_event_system.car_models.fields.power_type"
              }}
              @type="select"
              as |field|
            >
              <field.Control as |select|>
                {{#each POWER_TYPES as |powerType|}}
                  <select.Option @value={{powerType}}>
                    {{i18n
                      (concat
                        "discourse_event_system.car_models.power_types."
                        powerType
                      )
                    }}
                  </select.Option>
                {{/each}}
              </field.Control>
            </form.Field>
          </div>
        </div>

        <form.Actions class="des-car-model-editor__footer">
          <form.Submit @label="discourse_event_system.car_models.save" />
          <form.Button
            class="btn-default"
            @action={{this.cancel}}
            @label="discourse_event_system.car_models.cancel"
          />
        </form.Actions>
      </Form>
    </div>
  </template>
}
