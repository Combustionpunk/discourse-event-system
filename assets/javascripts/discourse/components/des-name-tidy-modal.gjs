import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import DButton from "discourse/ui-kit/d-button";
import DConditionalLoadingSpinner from "discourse/ui-kit/d-conditional-loading-spinner";
import DModal from "discourse/ui-kit/d-modal";
import DModalCancel from "discourse/ui-kit/d-modal-cancel";
import { i18n } from "discourse-i18n";

export default class DesNameTidyModal extends Component {
  @tracked changes = [];
  @tracked isApplying = false;
  @tracked isLoading = true;
  @tracked prefixes = [];
  @tracked selectedIds = [];

  isSelected = (id) => this.selectedIds.includes(id);

  constructor() {
    super(...arguments);
    this.#load();
  }

  get selectedCount() {
    return this.selectedIds.length;
  }

  get allSelected() {
    return (
      this.changes.length > 0 && this.selectedIds.length === this.changes.length
    );
  }

  @action
  toggleRow(id, event) {
    this.selectedIds = event.target.checked
      ? [...this.selectedIds, id]
      : this.selectedIds.filter((selected) => selected !== id);
  }

  @action
  toggleAll(event) {
    this.selectedIds = event.target.checked
      ? this.changes.map((row) => row.id)
      : [];
  }

  @action
  async apply() {
    this.isApplying = true;
    try {
      await ajax("/des/admin/models/name-tidy.json", {
        type: "POST",
        data: { ids: this.selectedIds },
      });
      this.args.closeModal();
      this.args.model.onApplied?.();
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.isApplying = false;
    }
  }

  async #load() {
    try {
      const result = await ajax("/des/admin/models/name-tidy.json");
      this.changes = result.changes;
      this.prefixes = result.prefixes;
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.isLoading = false;
    }
  }

  <template>
    <DModal
      class="des-name-tidy-modal"
      @closeModal={{@closeModal}}
      @title={{i18n "discourse_event_system.car_models.tidy.title"}}
    >
      <:body>
        <DConditionalLoadingSpinner @condition={{this.isLoading}}>
          <p class="des-name-tidy-modal__intro">
            {{i18n
              "discourse_event_system.car_models.tidy.intro"
              prefixes=(joinPrefixes this.prefixes)
            }}
          </p>
          {{#if this.changes.length}}
            <table class="des-name-tidy-modal__table">
              <thead>
                <tr>
                  <th>
                    <input
                      aria-label={{i18n
                        "discourse_event_system.car_models.tidy.select_all"
                      }}
                      checked={{this.allSelected}}
                      type="checkbox"
                      {{on "change" this.toggleAll}}
                    />
                  </th>
                  <th>{{i18n
                      "discourse_event_system.car_models.tidy.manufacturer"
                    }}</th>
                  <th>{{i18n
                      "discourse_event_system.car_models.tidy.current"
                    }}</th>
                  <th>{{i18n
                      "discourse_event_system.car_models.tidy.proposed"
                    }}</th>
                </tr>
              </thead>
              <tbody>
                {{#each this.changes as |row|}}
                  <tr data-model-id={{row.id}}>
                    <td>
                      <input
                        aria-label={{row.proposed}}
                        checked={{this.isSelected row.id}}
                        type="checkbox"
                        {{on "change" (fn this.toggleRow row.id)}}
                      />
                    </td>
                    <td>{{row.manufacturer_name}}</td>
                    <td>{{row.current}}</td>
                    <td>
                      {{row.proposed}}
                      {{#if row.duplicate_of}}
                        <div class="des-name-tidy-modal__clash">
                          {{i18n
                            "discourse_event_system.car_models.tidy.clash"
                            name=row.duplicate_of.name
                          }}
                        </div>
                      {{/if}}
                    </td>
                  </tr>
                {{/each}}
              </tbody>
            </table>
          {{else}}
            <p>{{i18n "discourse_event_system.car_models.tidy.nothing"}}</p>
          {{/if}}
        </DConditionalLoadingSpinner>
      </:body>
      <:footer>
        <DButton
          class="btn-primary des-name-tidy-modal__apply"
          @action={{this.apply}}
          @disabled={{if this.selectedCount false true}}
          @isLoading={{this.isApplying}}
          @translatedLabel={{i18n
            "discourse_event_system.car_models.tidy.apply"
            count=this.selectedCount
          }}
        />
        <DModalCancel @close={{@closeModal}} />
      </:footer>
    </DModal>
  </template>
}

function joinPrefixes(prefixes) {
  return prefixes.join(", ");
}
