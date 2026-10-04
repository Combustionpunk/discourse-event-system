import { fn } from "@ember/helper";
import { LinkTo } from "@ember/routing";
import { modifier } from "ember-modifier";
import DMenu from "discourse/float-kit/components/d-menu";
import lightbox from "discourse/lib/lightbox";
import DButton from "discourse/ui-kit/d-button";
import DDropdownMenu from "discourse/ui-kit/d-dropdown-menu";
import dAvatar from "discourse/ui-kit/helpers/d-avatar";
import { i18n } from "discourse-i18n";
import DesAddCarModal from "../components/des-add-car-modal";
import DesCarModelEditForm from "../components/des-car-model-edit-form";
import { logoBackdrop } from "../lib/des-logo-backdrop";

const applyLightbox = modifier((element) => {
  lightbox(element);
});

export default <template>
  <div class="car-models-container des-car-model-detail">
    <LinkTo class="des-car-model-detail__back" @route="car-models">
      {{i18n "discourse_event_system.car_model_detail.back"}}
    </LinkTo>

    <div class="des-car-model-detail__layout">
      <div class="des-car-model-detail__art">
        {{#if @controller.carModel.box_art_full_url}}
          <div class="des-car-model-detail__gallery" {{applyLightbox}}>
            <a
              class="lightbox des-car-model-detail__art-link"
              data-target-height={{@controller.carModel.box_art_height}}
              data-target-width={{@controller.carModel.box_art_width}}
              href={{@controller.carModel.box_art_full_url}}
              title={{@controller.carModel.name}}
            >
              <img
                alt={{@controller.carModel.name}}
                src={{@controller.carModel.box_art_full_url}}
              />
            </a>
          </div>
        {{else}}
          <div
            aria-hidden="true"
            class="des-model-card__art-placeholder des-car-model-detail__placeholder"
          >
            {{#if @controller.carModel.manufacturer_logo_url}}
              <img
                alt=""
                src={{@controller.carModel.manufacturer_logo_url}}
                {{logoBackdrop}}
              />
            {{else}}
              🏭
            {{/if}}
          </div>
        {{/if}}
      </div>

      <div class="des-car-model-detail__info">
        <div class="des-car-model-detail__manufacturer">
          {{#if @controller.carModel.manufacturer_logo_url}}
            <img
              alt=""
              class="des-car-model-detail__logo"
              src={{@controller.carModel.manufacturer_logo_url}}
            />
          {{/if}}
          <span>{{@controller.carModel.manufacturer_name}}</span>
        </div>

        <div class="des-car-model-detail__title-row">
          <h1 class="des-car-model-detail__title">
            {{@controller.carModel.name}}
          </h1>
          {{#if @controller.isAdmin}}
            <DMenu
              @icon="ellipsis"
              @identifier="des-car-model-detail-actions"
              @title={{i18n "discourse_event_system.car_models.actions_menu"}}
              @triggerClass="btn-flat des-car-model-detail__menu-trigger"
            >
              <:content as |args|>
                <DDropdownMenu as |dropdown|>
                  <dropdown.item>
                    <DButton
                      class="btn-transparent des-car-model-detail__edit"
                      @action={{fn @controller.startEditAndClose args.close}}
                      @icon="pencil"
                      @label="discourse_event_system.car_models.edit"
                    />
                  </dropdown.item>
                  <dropdown.item>
                    <DButton
                      class="btn-transparent btn-danger des-car-model-detail__delete"
                      @action={{fn @controller.deleteAndClose args.close}}
                      @icon="trash-can"
                      @label="discourse_event_system.car_models.delete"
                    />
                  </dropdown.item>
                </DDropdownMenu>
              </:content>
            </DMenu>
          {{/if}}
        </div>

        {{#if @controller.carModel.racer_count}}
          <div class="des-model-card__racers">
            {{i18n
              "discourse_event_system.car_models.racer_count"
              count=@controller.carModel.racer_count
            }}
          </div>
        {{/if}}

        <dl class="des-car-model-detail__specs">
          {{#each @controller.specs as |spec|}}
            <div class="des-car-model-detail__spec">
              <dt>{{spec.label}}</dt>
              <dd>{{spec.value}}</dd>
            </div>
          {{/each}}
        </dl>

        {{#if @controller.currentUser}}
          <div class="des-car-model-detail__actions">
            {{#if @controller.inGarage}}
              <LinkTo
                class="des-model-card__in-garage"
                @model={{@controller.currentUser.username}}
                @route="user.garage"
              >
                {{i18n "discourse_event_system.car_models.in_garage"}}
              </LinkTo>
            {{else}}
              <DButton
                class="btn-primary des-car-model-detail__garage"
                @action={{@controller.openAddCar}}
                @icon="plus"
                @label="discourse_event_system.car_models.add_to_garage"
              />
            {{/if}}
          </div>
        {{/if}}

        {{#if @controller.isEditing}}
          <DesCarModelEditForm
            @chassisTypes={{@controller.chassisTypes}}
            @model={{@controller.carModel}}
            @onCancel={{@controller.cancelEdit}}
            @onSaved={{@controller.onSaved}}
            @scales={{@controller.scales}}
          />
        {{/if}}
      </div>
    </div>

    {{#if @model.racers}}
      <section class="des-car-model-detail__section">
        <h2>{{i18n "discourse_event_system.car_model_detail.racers"}}</h2>
        <ul class="des-car-model-detail__racers">
          {{#each @model.racers as |racer|}}
            <li>
              <LinkTo
                class="des-car-model-detail__racer"
                @model={{racer.username}}
                @route="user.garage"
              >
                {{dAvatar racer imageSize="medium"}}
                <span>{{racer.username}}</span>
              </LinkTo>
            </li>
          {{/each}}
        </ul>
      </section>
    {{else if @controller.currentUser}}
      <section class="des-car-model-detail__section">
        <h2>{{i18n "discourse_event_system.car_model_detail.racers"}}</h2>
        <p class="des-car-model-detail__empty">
          {{i18n "discourse_event_system.car_model_detail.no_racers"}}
        </p>
      </section>
    {{/if}}

    <section class="des-car-model-detail__section">
      <h2>{{i18n "discourse_event_system.car_model_detail.eligible_classes"}}</h2>
      {{#if @model.eligible_classes.length}}
        <ul class="des-car-model-detail__classes">
          {{#each @model.eligible_classes as |eligibleClass|}}
            <li class="des-car-model-detail__class">
              {{eligibleClass.name}}
              {{#if eligibleClass.organisation_name}}
                <span class="des-car-model-detail__class-org">
                  {{eligibleClass.organisation_name}}
                </span>
              {{/if}}
            </li>
          {{/each}}
        </ul>
      {{else}}
        <p class="des-car-model-detail__empty">
          {{i18n "discourse_event_system.car_model_detail.no_classes"}}
        </p>
      {{/if}}
    </section>

    {{#if @controller.showAddCarModal}}
      <DesAddCarModal
        @manufacturerId={{@controller.carModel.manufacturer_id}}
        @modelId={{@controller.carModel.id}}
        @onClose={{@controller.closeAddCar}}
        @onSave={{@controller.onCarAdded}}
      />
    {{/if}}
  </div>
</template>
