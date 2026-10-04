import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import DMenu from "discourse/float-kit/components/d-menu";
import DButton from "discourse/ui-kit/d-button";
import DDropdownMenu from "discourse/ui-kit/d-dropdown-menu";
import { i18n } from "discourse-i18n";

// Specs matching these defaults are omitted from the spec line.
export const DEFAULT_SCALE = "1/10";
export const DEFAULT_POWER_TYPE = "electric";

export function modelSpecLine(model) {
  const parts = [model.chassis_type, model.driveline, model.year_released];

  if (model.scale && model.scale !== DEFAULT_SCALE) {
    parts.push(model.scale);
  }

  if (model.power_type && model.power_type !== DEFAULT_POWER_TYPE) {
    parts.push(
      i18n(
        `discourse_event_system.car_models.power_types.${model.power_type}`,
        { defaultValue: model.power_type }
      )
    );
  }

  return parts.filter(Boolean).join(" · ");
}

export default class DesCarModelCard extends Component {
  get specLine() {
    return modelSpecLine(this.args.model);
  }

  get isPending() {
    return this.args.model.status === "pending";
  }

  @action
  runMenuAction(callback, close) {
    close();
    callback(this.args.model);
  }

  <template>
    <div
      class="des-model-card {{if this.isPending 'des-model-card--pending'}}"
      data-model-id={{@model.id}}
    >
      <div class="des-model-card__name">
        <span class="des-model-card__title">{{@model.name}}</span>
        {{#if this.isPending}}
          <span class="des-model-card__pending-tag">
            {{i18n "discourse_event_system.car_models.pending"}}
          </span>
        {{/if}}
      </div>

      {{#if this.specLine}}
        <div class="des-model-card__specs">{{this.specLine}}</div>
      {{/if}}

      {{#if @showSuggestedBy}}
        {{#if @model.created_by}}
          <div class="des-model-card__suggested-by">
            {{i18n
              "discourse_event_system.car_models.suggested_by"
              username=@model.created_by
            }}
          </div>
        {{/if}}
      {{/if}}

      <div class="des-model-card__actions">
        {{#if @canAddToGarage}}
          {{#unless this.isPending}}
            <DButton
              class="btn-primary btn-small des-model-card__garage"
              @action={{fn @onAddToGarage @model}}
              @icon="plus"
              @label="discourse_event_system.car_models.add_to_garage"
            />
          {{/unless}}
        {{/if}}

        {{#if @canManage}}
          <DMenu
            @icon="ellipsis"
            @identifier="des-model-card-actions"
            @title={{i18n "discourse_event_system.car_models.actions_menu"}}
            @triggerClass="btn-flat btn-small des-model-card__menu-trigger"
          >
            <:content as |args|>
              <DDropdownMenu as |dropdown|>
                <dropdown.item>
                  <DButton
                    class="btn-transparent des-model-card__edit"
                    @action={{fn this.runMenuAction @onEdit args.close}}
                    @icon="pencil"
                    @label="discourse_event_system.car_models.edit"
                  />
                </dropdown.item>
                <dropdown.item>
                  <DButton
                    class="btn-transparent btn-danger des-model-card__delete"
                    @action={{fn this.runMenuAction @onDelete args.close}}
                    @icon="trash-can"
                    @label="discourse_event_system.car_models.delete"
                  />
                </dropdown.item>
              </DDropdownMenu>
            </:content>
          </DMenu>
        {{/if}}
      </div>

      {{yield}}
    </div>
  </template>
}
