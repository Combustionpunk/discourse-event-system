import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { LinkTo } from "@ember/routing";
import { modifier } from "ember-modifier";
import DMenu from "discourse/float-kit/components/d-menu";
import lightbox from "discourse/lib/lightbox";
import DButton from "discourse/ui-kit/d-button";
import DDropdownMenu from "discourse/ui-kit/d-dropdown-menu";
import { i18n } from "discourse-i18n";
import DesBoxArtPlaceholder from "./des-box-art-placeholder";

// Specs matching these defaults are omitted from the spec line.
export const DEFAULT_SCALE = "1/10";
export const DEFAULT_POWER_TYPE = "electric";

const KNOWN_POWER_TYPES = ["electric", "nitro", "petrol", "both"];

export function powerTypeLabel(powerType) {
  return KNOWN_POWER_TYPES.includes(powerType)
    ? i18n(`discourse_event_system.car_models.power_types.${powerType}`)
    : powerType;
}

export function carModelSlug(model) {
  const words = `${model.manufacturer_name || ""} ${model.name || ""}`
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
  return words ? `${model.id}-${words}` : String(model.id);
}

export function modelSpecLine(model) {
  const parts = [model.chassis_type, model.driveline, model.year_released];

  if (model.scale && model.scale !== DEFAULT_SCALE) {
    parts.push(model.scale);
  }

  if (model.power_type && model.power_type !== DEFAULT_POWER_TYPE) {
    parts.push(powerTypeLabel(model.power_type));
  }

  return parts.filter(Boolean).join(" · ");
}

export default class DesCarModelCard extends Component {
  applyLightbox = modifier((element) => {
    lightbox(element);
  });

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
      <div class="des-model-card__art">
        {{#if @model.box_art_url}}
          <div class="des-model-card__art-gallery" {{this.applyLightbox}}>
            <a
              aria-label={{i18n
                "discourse_event_system.car_models.box_art.view"
                name=@model.name
              }}
              class="lightbox des-model-card__art-link"
              data-target-height={{@model.box_art_height}}
              data-target-width={{@model.box_art_width}}
              href={{@model.box_art_full_url}}
              title={{@model.name}}
            >
              <img alt="" loading="lazy" src={{@model.box_art_url}} />
            </a>
          </div>
        {{else}}
          <DesBoxArtPlaceholder
            @logoUrl={{@placeholderLogoUrl}}
            @onSuggest={{if @canSuggestBoxArt (fn @onSuggestBoxArt @model)}}
            @pending={{@boxArtPending}}
          />
        {{/if}}
      </div>

      {{#if @showManufacturer}}
        <div class="des-model-card__manufacturer">
          {{@model.manufacturer_name}}
        </div>
      {{/if}}

      <div class="des-model-card__name">
        <LinkTo
          class="des-model-card__title"
          @model={{carModelSlug @model}}
          @route="car-model"
        >{{@model.name}}</LinkTo>
        {{#if this.isPending}}
          <span class="des-model-card__pending-tag">
            {{i18n "discourse_event_system.car_models.pending"}}
          </span>
        {{/if}}
      </div>

      {{#if this.specLine}}
        <div class="des-model-card__specs">{{this.specLine}}</div>
      {{/if}}

      {{#if @model.racer_count}}
        <div class="des-model-card__racers">
          {{i18n
            "discourse_event_system.car_models.racer_count"
            count=@model.racer_count
          }}
        </div>
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
            {{#if @inGarage}}
              <LinkTo
                class="des-model-card__in-garage"
                @model={{@garageUsername}}
                @route="user.garage"
              >
                {{i18n "discourse_event_system.car_models.in_garage"}}
              </LinkTo>
            {{else}}
              <DButton
                class="btn-primary btn-small des-model-card__garage"
                @action={{fn @onAddToGarage @model}}
                @icon="plus"
                @label="discourse_event_system.car_models.add_to_garage"
              />
            {{/if}}
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
                    class="btn-transparent des-model-card__merge"
                    @action={{fn this.runMenuAction @onMerge args.close}}
                    @icon="code-merge"
                    @label="discourse_event_system.car_models.merge_into"
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
