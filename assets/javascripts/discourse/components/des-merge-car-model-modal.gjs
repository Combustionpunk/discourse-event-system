import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { concat, fn, hash } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { eq } from "discourse/truth-helpers";
import DButton from "discourse/ui-kit/d-button";
import DFilterInput from "discourse/ui-kit/d-filter-input";
import DModal from "discourse/ui-kit/d-modal";
import DModalCancel from "discourse/ui-kit/d-modal-cancel";
import { i18n } from "discourse-i18n";

const PREVIEW_COUNTS = [
  "garage_entries",
  "duplicate_garage_entries",
  "bookings",
  "class_types",
  "compatibility_rules",
  "image_suggestions",
];

export default class DesMergeCarModelModal extends Component {
  @tracked allManufacturers = false;
  @tracked filter = "";
  @tracked isMerging = false;
  @tracked preview = null;
  @tracked target = null;

  get source() {
    return this.args.model.source;
  }

  get candidates() {
    const term = this.filter.trim().toLowerCase();
    return this.args.model.models
      .filter(
        (m) =>
          m.id !== this.source.id &&
          m.status !== "rejected" &&
          (this.allManufacturers ||
            m.manufacturer_id === this.source.manufacturer_id) &&
          (!term ||
            `${m.manufacturer_name} ${m.name}`.toLowerCase().includes(term))
      )
      .slice(0, 50);
  }

  get previewRows() {
    if (!this.preview) {
      return [];
    }
    return PREVIEW_COUNTS.map((key) => ({
      key,
      count: this.preview[key],
      label: i18n(`discourse_event_system.car_models.merge.counts.${key}`, {
        count: this.preview[key],
      }),
    }));
  }

  get boxArtNote() {
    return this.preview
      ? i18n(
          `discourse_event_system.car_models.merge.box_art.${this.preview.box_art}`
        )
      : null;
  }

  @action
  onFilter(event) {
    this.filter = event.target.value;
  }

  @action
  toggleAllManufacturers(event) {
    this.allManufacturers = event.target.checked;
  }

  @action
  async selectTarget(model) {
    this.target = model;
    this.preview = null;
    try {
      this.preview = await ajax(
        `/des/admin/models/${this.source.id}/merge-preview.json`,
        { data: { target_id: model.id } }
      );
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  async merge() {
    this.isMerging = true;
    try {
      await ajax(`/des/admin/models/${this.source.id}/merge.json`, {
        type: "POST",
        data: { target_id: this.target.id },
      });
      this.args.closeModal();
      this.args.model.onMerged?.(this.target);
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.isMerging = false;
    }
  }

  <template>
    <DModal
      class="des-merge-modal"
      @closeModal={{@closeModal}}
      @title={{i18n
        "discourse_event_system.car_models.merge.title"
        name=this.source.name
      }}
    >
      <:body>
        <p class="des-merge-modal__intro">
          {{i18n "discourse_event_system.car_models.merge.intro"}}
        </p>
        <DFilterInput
          class="des-merge-modal__search"
          placeholder={{i18n
            "discourse_event_system.car_models.merge.search_placeholder"
          }}
          @filterAction={{this.onFilter}}
          @icons={{hash left="magnifying-glass"}}
          @value={{this.filter}}
        />
        <label class="des-merge-modal__scope">
          <input
            checked={{this.allManufacturers}}
            type="checkbox"
            {{on "change" this.toggleAllManufacturers}}
          />
          {{i18n "discourse_event_system.car_models.merge.all_manufacturers"}}
        </label>

        <ul class="des-merge-modal__candidates">
          {{#each this.candidates as |candidate|}}
            <li>
              <DButton
                class="btn-transparent des-merge-modal__candidate
                  {{if
                    (eq candidate.id this.target.id)
                    'des-merge-modal__candidate--selected'
                  }}"
                data-model-id={{candidate.id}}
                @action={{fn this.selectTarget candidate}}
                @translatedLabel={{if
                  this.allManufacturers
                  (concat candidate.manufacturer_name " " candidate.name)
                  candidate.name
                }}
              />
            </li>
          {{else}}
            <li class="des-merge-modal__empty">
              {{i18n "discourse_event_system.car_models.merge.no_candidates"}}
            </li>
          {{/each}}
        </ul>

        {{#if this.preview}}
          <div class="des-merge-modal__preview">
            <h3>{{i18n
                "discourse_event_system.car_models.merge.preview_heading"
                source=this.preview.source.label
                target=this.preview.target.label
              }}</h3>
            <ul>
              {{#each this.previewRows as |row|}}
                <li data-count-key={{row.key}}>{{row.label}}</li>
              {{/each}}
              <li data-count-key="box_art">{{this.boxArtNote}}</li>
            </ul>
            <p class="des-merge-modal__warning">
              {{i18n "discourse_event_system.car_models.merge.warning"}}
            </p>
          </div>
        {{/if}}
      </:body>
      <:footer>
        <DButton
          class="btn-danger des-merge-modal__confirm"
          @action={{this.merge}}
          @disabled={{if this.preview false true}}
          @isLoading={{this.isMerging}}
          @label="discourse_event_system.car_models.merge.confirm"
        />
        <DModalCancel @close={{@closeModal}} />
      </:footer>
    </DModal>
  </template>
}
