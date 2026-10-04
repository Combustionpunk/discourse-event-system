import { tracked } from "@glimmer/tracking";
import Controller from "@ember/controller";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { i18n } from "discourse-i18n";
import { carModelSlug, powerTypeLabel } from "../components/des-car-model-card";
import DesMergeCarModelModal from "../components/des-merge-car-model-modal";

export default class CarModelController extends Controller {
  @service currentUser;
  @service dialog;
  @service modal;
  @service router;
  @service toasts;

  @tracked addedToGarage = false;
  @tracked boxArtSubmitted = false;
  @tracked chassisTypes = [];
  @tracked isEditing = false;
  @tracked scales = [];
  @tracked showAddCarModal = false;

  get carModel() {
    return this.model.model;
  }

  get boxArtPending() {
    return this.model.my_pending_box_art || this.boxArtSubmitted;
  }

  get inGarage() {
    return this.carModel.in_garage || this.addedToGarage;
  }

  get isAdmin() {
    return !!this.currentUser?.admin;
  }

  get specs() {
    const m = this.carModel;
    const powerType = m.power_type ? powerTypeLabel(m.power_type) : null;
    return [
      ["chassis_type", m.chassis_type],
      ["driveline", m.driveline],
      ["scale", m.scale],
      ["power_type", powerType],
      ["year", m.year_released],
    ]
      .filter(([, value]) => value)
      .map(([key, value]) => ({
        label: i18n(`discourse_event_system.car_models.fields.${key}`),
        value,
      }));
  }

  @action
  openAddCar() {
    this.showAddCarModal = true;
  }

  @action
  closeAddCar() {
    this.showAddCarModal = false;
  }

  @action
  onCarAdded() {
    this.showAddCarModal = false;
    this.addedToGarage = true;
  }

  @action
  async startEdit() {
    if (!this.scales.length) {
      try {
        const [scales, chassis] = await Promise.all([
          ajax("/des/admin/scales.json"),
          ajax("/des/admin/chassis-types.json"),
        ]);
        this.scales = scales.scales.map((s) => s.name);
        this.chassisTypes = chassis.chassis_types.map((c) => c.name);
      } catch (error) {
        popupAjaxError(error);
      }
    }
    this.isEditing = true;
  }

  @action
  startEditAndClose(close) {
    close();
    this.startEdit();
  }

  @action
  deleteAndClose(close) {
    close();
    this.deleteModel();
  }

  @action
  async suggestBoxArt(upload) {
    try {
      const result = await ajax(
        `/des/car-models/${this.carModel.id}/box-art.json`,
        { type: "POST", data: { upload_id: upload.id } }
      );
      if (result.applied) {
        this.toasts.success({
          duration: "short",
          data: {
            message: i18n("discourse_event_system.car_models.box_art.applied"),
          },
        });
        this.router.refresh();
      } else {
        this.boxArtSubmitted = true;
        this.toasts.success({
          data: {
            message: i18n("discourse_event_system.car_models.box_art.submitted"),
          },
        });
      }
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  async mergeAndClose(close) {
    close();
    try {
      const data = await ajax("/des/car-models.json");
      this.modal.show(DesMergeCarModelModal, {
        model: {
          source: this.carModel,
          models: data.models_by_manufacturer.flatMap((group) => group.models),
          onMerged: (target) =>
            this.router.transitionTo("car-model", carModelSlug(target)),
        },
      });
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  cancelEdit() {
    this.isEditing = false;
  }

  @action
  onSaved() {
    this.isEditing = false;
    this.router.refresh();
  }

  @action
  async deleteModel() {
    const confirmed = await this.dialog.deleteConfirm({
      message: i18n("discourse_event_system.car_models.confirm_delete", {
        name: this.carModel.name,
      }),
    });
    if (!confirmed) {
      return;
    }
    try {
      await ajax(`/des/admin/models/${this.carModel.id}.json`, {
        type: "DELETE",
      });
      this.router.transitionTo("car-models");
    } catch (error) {
      popupAjaxError(error);
    }
  }
}
