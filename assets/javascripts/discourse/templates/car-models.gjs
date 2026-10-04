import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { LinkTo } from "@ember/routing";
import { eq, or } from "discourse/truth-helpers";
import DButton from "discourse/ui-kit/d-button";
import DEmptyState from "discourse/ui-kit/d-empty-state";
import { i18n } from "discourse-i18n";
import DesAddCarModal from "../components/des-add-car-modal";
import DesCarModelCard from "../components/des-car-model-card";
import DesCarModelFilters from "../components/des-car-model-filters";
import {
  FormActions,
  ModelSpecFields,
} from "../components/des-car-model-form-fields";
import DesLogoUploader from "../components/des-logo-uploader";
import DesPendingModelsPanel from "../components/des-pending-models-panel";
import DesSuggestModelModal from "../components/des-suggest-model-modal";

const has = (set, value) => set.has(value);

const ModelCard = <template>
  <DesCarModelCard
    @boxArtPending={{has
      @controller.pendingBoxArtModelIds
      @model.id
    }}
    @canAddToGarage={{@controller.currentUser}}
    @canManage={{@controller.isAdmin}}
    @canSuggestBoxArt={{@controller.currentUser}}
    @garageUsername={{@controller.currentUser.username}}
    @inGarage={{has @controller.garageModelIds @model.id}}
    @model={{@model}}
    @onAddToGarage={{@controller.addToGarage}}
    @onDelete={{@controller.deleteModel}}
    @onEdit={{@controller.startEditModel}}
    @onMerge={{@controller.openMerge}}
    @onSuggestBoxArt={{@controller.suggestBoxArt}}
    @placeholderLogoUrl={{@placeholderLogoUrl}}
    @showManufacturer={{@showManufacturer}}
  @showSuggestedBy={{@controller.isAdmin}}
  >
    {{#if (eq @controller.editingModelId @model.id)}}
      <div class="add-model-form des-model-card__edit-form">
        <div class="org-form-row">
          <div class="org-form-field">
            <label>{{i18n
                "discourse_event_system.car_models.fields.name"
              }}</label>
            <input
              type="text"
              value={{@controller.editModelForm.name}}
              {{on
                "input"
                (fn @controller.updateEditModelField "name")
              }}
            />
          </div>
          <ModelSpecFields
            @chassisTypes={{@controller.chassisTypes}}
            @form={{@controller.editModelForm}}
            @onChange={{@controller.updateEditModelField}}
            @scales={{@controller.scales}}
          />
          <div class="org-form-field des-model-card__box-art-field">
            <label>{{i18n
                "discourse_event_system.car_models.box_art.label"
              }}</label>
            <DesLogoUploader
              @changeLabel={{i18n
                "discourse_event_system.car_models.box_art.change"
              }}
              @helpText={{i18n
                "discourse_event_system.car_models.box_art.help"
              }}
              @logoUrl={{@controller.editModelForm.box_art_url}}
              @onRemove={{@controller.removeEditBoxArt}}
              @onUpload={{@controller.editBoxArtUploaded}}
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
          @onCancel={{@controller.cancelEditModel}}
          @onConfirm={{@controller.saveEditModel}}
        />
      </div>
    {{/if}}
  </DesCarModelCard>
</template>;

export default <template>
  <div class="car-models-container">
    <div class="events-nav">
      <LinkTo class="btn btn-default" @route="events">📅
        {{i18n "discourse_event_system.car_models.nav.events"}}</LinkTo>
      <LinkTo class="btn btn-default" @route="organisations">🏢
        {{i18n "discourse_event_system.car_models.nav.organisations"}}</LinkTo>
      <LinkTo class="btn btn-default" @route="venues">📍
        {{i18n "discourse_event_system.car_models.nav.venues"}}</LinkTo>
      <LinkTo class="btn btn-primary" @route="car-models">🚗
        {{i18n "discourse_event_system.car_models.nav.car_models"}}</LinkTo>
    </div>

    <div class="manage-section-header des-car-models-header">
      <h1>🚗 {{i18n "discourse_event_system.car_models.title"}}</h1>
      {{#if @controller.isAdmin}}
        <DButton
          class="btn-default des-car-models-header__tidy"
          @action={{@controller.openNameTidy}}
          @icon="wand-magic-sparkles"
          @label="discourse_event_system.car_models.tidy_names"
        />
      {{/if}}
    </div>

    <DesCarModelFilters
      @groups={{@controller.filterGroups}}
      @hasActiveFilters={{@controller.hasActiveFilters}}
      @onClear={{@controller.clearFilters}}
      @onClearSearch={{@controller.clearSearch}}
      @onSearchInput={{@controller.onSearchInput}}
      @onSort={{@controller.setSort}}
      @onToggle={{@controller.toggleFilter}}
      @searchValue={{@controller.searchValue}}
      @sortOptions={{@controller.sortOptions}}
    />

    <DesPendingModelsPanel
      @approvingModelId={{@controller.approvingModelId}}
      @imageSuggestions={{@controller.imageSuggestions}}
      @models={{@controller.pendingModels}}
      @onApprove={{@controller.startApproveModel}}
      @onApproveImage={{@controller.approveImageSuggestion}}
      @onReject={{@controller.rejectModel}}
      @onRejectImage={{@controller.rejectImageSuggestion}}
    >
      <div class="add-model-form">
        <div class="org-form-row">
          <ModelSpecFields
            @chassisTypes={{@controller.chassisTypes}}
            @form={{@controller.approveModelForm}}
            @onChange={{@controller.updateApproveField}}
            @scales={{@controller.scales}}
          />
        </div>
        <FormActions
          @confirmLabel="discourse_event_system.car_models.confirm"
          @onCancel={{@controller.cancelApproveModel}}
          @onConfirm={{@controller.confirmApproveModel}}
        />
      </div>
    </DesPendingModelsPanel>

    {{#unless (or @controller.hasActiveFilters @controller.isFlatView)}}
      <div class="des-manufacturer-grid">
        {{#each @controller.manufacturerTiles as |tile|}}
          <DButton
            class="btn-transparent des-manufacturer-tile
              {{if tile.isEmpty 'des-manufacturer-tile--empty'}}"
            data-manufacturer-id={{tile.manufacturer.id}}
            @action={{fn @controller.selectManufacturerTile tile}}
            @disabled={{tile.isDisabled}}
            @translatedTitle={{tile.title}}
          >
            <span class="des-manufacturer-tile__logo">
              {{#if tile.manufacturer.logo_url}}
                <img alt="" src={{tile.manufacturer.logo_url}} />
              {{else}}
                <span class="des-manufacturer-tile__placeholder">🏭</span>
              {{/if}}
            </span>
            <span class="des-manufacturer-tile__name">
              {{tile.manufacturer.name}}
            </span>
            <span class="des-manufacturer-tile__count">{{tile.matchCount}}</span>
          </DButton>
        {{/each}}
      </div>
    {{/unless}}

    {{#if @controller.currentUser}}
      {{#unless @controller.isAdmin}}
        <div class="des-suggest-bar">
          <DButton
            class="btn-small"
            @action={{@controller.toggleSuggestManufacturer}}
            @icon={{if @controller.showSuggestManufacturer "xmark" "plus"}}
            @label={{if
              @controller.showSuggestManufacturer
              "discourse_event_system.car_models.cancel"
              "discourse_event_system.car_models.suggest_manufacturer"
            }}
          />
          <DButton
            class="btn-small"
            @action={{fn @controller.openSuggestModelModal null}}
            @icon="plus"
            @label="discourse_event_system.car_models.suggest_model"
          />
        </div>

        {{#if @controller.showSuggestManufacturer}}
          <div class="add-model-form">
            <h4>{{i18n
                "discourse_event_system.car_models.suggest_manufacturer_heading"
              }}</h4>
            <p class="field-help">{{i18n
                "discourse_event_system.car_models.suggest_manufacturer_help"
              }}</p>
            <div class="org-form-row">
              <div class="org-form-field">
                <label>{{i18n
                    "discourse_event_system.car_models.manufacturer_name"
                  }}</label>
                <input
                  placeholder={{i18n
                    "discourse_event_system.car_models.manufacturer_name_placeholder"
                  }}
                  type="text"
                  value={{@controller.newManufacturerName}}
                  {{on "input" @controller.updateNewManufacturerName}}
                />
              </div>
            </div>
            <DButton
              class="btn-primary"
              @action={{@controller.suggestManufacturer}}
              @label="discourse_event_system.car_models.submit_suggestion"
            />
          </div>
        {{/if}}
      {{/unless}}
    {{/if}}

    {{#if @controller.isFlatView}}
      {{#if @controller.flatModels.length}}
        <section class="des-manufacturer-section des-manufacturer-section--flat">
          <div class="des-manufacturer-section__header">
            <h2 class="des-manufacturer-section__title">
              {{i18n "discourse_event_system.car_models.most_popular_heading"}}
            </h2>
          </div>
          <div class="des-model-grid">
            {{#each @controller.flatModels as |entry|}}
              <ModelCard
                @controller={{@controller}}
                @model={{entry.model}}
                @placeholderLogoUrl={{entry.logoUrl}}
                @showManufacturer={{true}}
              />
            {{/each}}
          </div>
        </section>
      {{else}}
        <DEmptyState
          @ctaAction={{@controller.clearFilters}}
          @ctaLabel={{i18n "discourse_event_system.car_models.filters.clear"}}
          @identifier="des-car-models"
          @title={{i18n "discourse_event_system.car_models.no_matches"}}
        />
      {{/if}}
    {{else}}
    {{#each @controller.manufacturerSections as |mfrSection|}}
      <section
        class="des-manufacturer-section"
        id="manufacturer-{{mfrSection.manufacturer.id}}"
      >
        <div class="des-manufacturer-section__header">
          <h2 class="des-manufacturer-section__title">
            {{#if mfrSection.manufacturer.logo_url}}
              <img
                alt=""
                class="des-manufacturer-section__logo"
                src={{mfrSection.manufacturer.logo_url}}
              />
            {{/if}}
            {{i18n
              "discourse_event_system.car_models.section_heading"
              manufacturer=mfrSection.manufacturer.name
              count=mfrSection.count
            }}
            {{#if (eq mfrSection.manufacturer.status "pending")}}
              <span class="des-model-card__pending-tag">
                {{i18n "discourse_event_system.car_models.pending_manufacturer"}}
              </span>
            {{/if}}
          </h2>
          {{#if @controller.isAdmin}}
            <DButton
              class="btn-small"
              @action={{fn @controller.startAddModel mfrSection.manufacturer.id}}
              @icon="plus"
              @label="discourse_event_system.car_models.add_model"
            />
          {{else if @controller.currentUser}}
            <DButton
              class="btn-small"
              @action={{fn @controller.openSuggestModelModal mfrSection.manufacturer}}
              @icon="plus"
              @label="discourse_event_system.car_models.suggest_model"
            />
          {{/if}}
        </div>

        {{#if (eq @controller.addingModelForManufacturerId mfrSection.manufacturer.id)}}
          <div class="add-model-form">
            <h4>{{i18n
                "discourse_event_system.car_models.add_model_heading"
                manufacturer=mfrSection.manufacturer.name
              }}</h4>
            <div class="org-form-row">
              <div class="org-form-field">
                <label>{{i18n
                    "discourse_event_system.car_models.fields.name_required"
                  }}</label>
                <input
                  placeholder={{i18n
                    "discourse_event_system.car_models.fields.name_placeholder"
                  }}
                  type="text"
                  value={{@controller.newModelForm.name}}
                  {{on "input" (fn @controller.updateNewModelField "name")}}
                />
              </div>
              <ModelSpecFields
                @chassisTypes={{@controller.chassisTypes}}
                @form={{@controller.newModelForm}}
                @onChange={{@controller.updateNewModelField}}
                @scales={{@controller.scales}}
              />
            </div>
            <FormActions
              @confirmLabel="discourse_event_system.car_models.add_model"
              @onCancel={{@controller.cancelAddModel}}
              @onConfirm={{@controller.confirmAddModel}}
            />
          </div>
        {{/if}}

        <div class="des-model-grid">
          {{#each mfrSection.models as |model|}}
            <ModelCard
              @controller={{@controller}}
              @model={{model}}
              @placeholderLogoUrl={{mfrSection.manufacturer.logo_url}}
            />
          {{/each}}
        </div>
      </section>
    {{else}}
      {{#if @controller.hasActiveFilters}}
        <DEmptyState
          @ctaAction={{@controller.clearFilters}}
          @ctaLabel={{i18n "discourse_event_system.car_models.filters.clear"}}
          @identifier="des-car-models"
          @title={{i18n "discourse_event_system.car_models.no_matches"}}
        />
      {{/if}}
    {{/each}}

    {{/if}}

    {{#if @controller.showAddCarModal}}
      <DesAddCarModal
        @manufacturerId={{@controller.addCarManufacturerId}}
        @modelId={{@controller.addCarModelId}}
        @onClose={{@controller.closeAddCarModal}}
        @onSave={{@controller.onCarAdded}}
      />
    {{/if}}

    {{#if @controller.showSuggestModelModal}}
      <DesSuggestModelModal
        @chassisTypes={{@controller.chassisTypes}}
        @manufacturers={{@controller.approvedManufacturers}}
        @onClose={{@controller.closeSuggestModelModal}}
        @onSave={{@controller.onModelSuggested}}
        @preselectedManufacturer={{@controller.suggestModelPreselectedManufacturer}}
        @scales={{@controller.scales}}
      />
    {{/if}}
  </div>
</template>
