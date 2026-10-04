import { fn } from "@ember/helper";
import { eq } from "discourse/truth-helpers";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";
import { modelSpecLine } from "./des-car-model-card";

const DesPendingModelsPanel = <template>
  {{#if @models.length}}
    <details class="des-pending-panel" open>
      <summary class="des-pending-panel__summary">
        {{i18n
          "discourse_event_system.car_models.pending_panel.title"
          count=@models.length
        }}
      </summary>

      <ul class="des-pending-panel__list">
        {{#each @models as |model|}}
          <li class="des-pending-panel__item" data-model-id={{model.id}}>
            <div class="des-pending-panel__details">
              <div class="des-pending-panel__name">
                <span class="des-pending-panel__manufacturer">
                  {{model.manufacturer_name}}
                </span>
                {{model.name}}
              </div>
              <div class="des-pending-panel__meta">
                {{modelSpecLine model}}
                {{#if model.created_by}}
                  <span class="des-pending-panel__suggested-by">
                    {{i18n
                      "discourse_event_system.car_models.pending_panel.suggested_by"
                      username=model.created_by
                    }}
                  </span>
                {{/if}}
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
      </ul>
    </details>
  {{/if}}
</template>;

export default DesPendingModelsPanel;
