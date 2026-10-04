import { tracked } from "@glimmer/tracking";
import Controller from "@ember/controller";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { i18n } from "discourse-i18n";
import { powerTypeLabel } from "../components/des-car-model-card";

export default class CarModelController extends Controller {
  @service currentUser;
  @service dialog;
  @service router;

  @tracked addedToGarage = false;
  @tracked chassisTypes = [];
  @tracked isEditing = false;
  @tracked scales = [];
  @tracked showAddCarModal = false;

  get carModel() {
    return this.model.model;
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
