import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { eq } from "discourse/truth-helpers";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";
import { modelSpecLine } from "./des-car-model-card";

const OPEN_STATE_KEY = "des-car-models-pending-panel-open";

function readOpenState() {
  try {
    return window.localStorage.getItem(OPEN_STATE_KEY) === "true";
  } catch {
    return false;
  }
}

function writeOpenState(isOpen) {
  try {
    window.localStorage.setItem(OPEN_STATE_KEY, String(isOpen));
  } catch {
    // Storage can be unavailable (private mode, blocked site data).
  }
}

const PendingModelMeta = <template>
  {{#let (modelSpecLine @model) as |specLine|}}
    {{#if specLine}}
      <span class="des-pending-panel__specs">{{specLine}}</span>
    {{/if}}
    {{#if @model.created_by}}
      <span
        class="des-pending-panel__suggested-by
          {{if specLine 'des-pending-panel__suggested-by--separated'}}"
      >
        {{i18n
          "discourse_event_system.car_models.pending_panel.suggested_by"
          username=@model.created_by
        }}
      </span>
    {{/if}}
  {{/let}}
</template>;

export default class DesPendingModelsPanel extends Component {
  @tracked isOpen = readOpenState();

  get totalCount() {
    return (
      (this.args.models?.length || 0) +
      (this.args.imageSuggestions?.length || 0)
    );
  }

  @action
  onToggle(event) {
    this.isOpen = event.target.open;
    writeOpenState(this.isOpen);
  }

  <template>
    {{#if this.totalCount}}
      <details
        class="des-pending-panel"
        open={{this.isOpen}}
        {{on "toggle" this.onToggle}}
      >
        <summary class="des-pending-panel__summary">
          {{i18n
            "discourse_event_system.car_models.pending_panel.title"
            count=this.totalCount
          }}
        </summary>

        <ul class="des-pending-panel__list">
          {{#each @models as |model|}}
            <li class="des-pending-panel__item" data-model-id={{model.id}}>
              {{#if model.box_art_url}}
                <a
                  class="des-pending-panel__art"
                  href={{model.box_art_full_url}}
                  rel="noopener noreferrer"
                  target="_blank"
                >
                  <img alt="" loading="lazy" src={{model.box_art_url}} />
                </a>
              {{/if}}

              <div class="des-pending-panel__details">
                <div class="des-pending-panel__name">
                  <span class="des-pending-panel__manufacturer">
                    {{model.manufacturer_name}}
                  </span>
                  {{model.name}}
                </div>
                <div class="des-pending-panel__meta">
                  <PendingModelMeta @model={{model}} />
                </div>
              </div>

              <div class="des-pending-panel__actions">
                <DButton
                  class="btn-primary btn-small des-pending-panel__approve"
                  @action={{fn @onApprove model}}
                  @icon="check"
                  @label="discourse_event_system.car_models.pending_panel.approve"
                />
                <DButton
                  class="btn-danger btn-small des-pending-panel__reject"
                  @action={{fn @onReject model}}
                  @icon="xmark"
                  @label="discourse_event_system.car_models.pending_panel.reject"
                />
              </div>

              {{#if (eq @approvingModelId model.id)}}
                <div class="des-pending-panel__approve-form">
                  {{yield}}
                </div>
              {{/if}}
            </li>
          {{/each}}

          {{#each @imageSuggestions as |suggestion|}}
            <li
              class="des-pending-panel__item des-pending-panel__item--box-art"
              data-image-suggestion-id={{suggestion.id}}
            >
              <a
                class="des-pending-panel__art"
                href={{suggestion.image_url}}
                rel="noopener noreferrer"
                target="_blank"
              >
                <img alt="" loading="lazy" src={{suggestion.image_url}} />
              </a>

              <div class="des-pending-panel__details">
                <div class="des-pending-panel__name">
                  <span class="des-pending-panel__manufacturer">
                    {{suggestion.manufacturer_name}}
                  </span>
                  {{suggestion.car_model_name}}
                  <span class="des-pending-panel__kind">
                    {{i18n
                      "discourse_event_system.car_models.pending_panel.box_art_heading"
                    }}
                  </span>
                </div>
                <div class="des-pending-panel__meta">
                  {{i18n
                    "discourse_event_system.car_models.pending_panel.suggested_by"
                    username=suggestion.suggested_by
                  }}
                </div>
              </div>

              <div class="des-pending-panel__actions">
                <DButton
                  class="btn-primary btn-small des-pending-panel__approve"
                  @action={{fn @onApproveImage suggestion}}
                  @icon="check"
                  @label="discourse_event_system.car_models.pending_panel.approve"
                />
                <DButton
                  class="btn-danger btn-small des-pending-panel__reject"
                  @action={{fn @onRejectImage suggestion}}
                  @icon="xmark"
                  @label="discourse_event_system.car_models.pending_panel.reject"
                />
              </div>
            </li>
          {{/each}}
        </ul>
      </details>
    {{/if}}
  </template>
}
