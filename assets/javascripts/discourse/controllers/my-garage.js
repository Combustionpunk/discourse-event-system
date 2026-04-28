import Controller from "@ember/controller";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { tracked } from "@glimmer/tracking";
import { inject as service } from "@ember/service";

export default class MyGarageController extends Controller {
  @service router;
  @tracked showAddForm = false;
  @tracked isSaving = false;
  @tracked availableModels = [];
  @tracked selectedModel = null;
  @tracked showSuggestModel = false;
  @tracked suggestedManufacturer = null;
  @tracked suggestModelName = "";
  @tracked suggestModelYear = "";
  @tracked suggestModelDriveline = "";
  @tracked newCar = {
    manufacturer_id: "",
    car_model_id: "",
    class_type_id: "",
    driveline: "",
    transponder_number: "",
    friendly_name: "",
  };

  drivelines = ["2WD", "4WD", "FWD", "Rear Motor"];
  @tracked scales = [];
  @tracked chassisTypes = [];
  @tracked suggestModelScale = "";
  @tracked suggestModelChassisType = "";
  @tracked editingCarId = null;
  @tracked editingCar = null;
  @tracked editModels = [];
  @tracked userTransponders = [];
  @tracked newCarTransponderMode = "registry";
  @tracked newCarTransponderNew = "";
  @tracked editCarTransponderMode = "registry";
  @tracked editCarTransponderNew = "";

  @action
  async toggleAddForm() {
    this.showAddForm = !this.showAddForm;
    this.resetForm();
    if (this.showAddForm) {
      await this.loadScalesAndChassisTypes();
      await this.loadUserTransponders();
    }
  }

  async loadScalesAndChassisTypes() {
    try {
      const [scalesResp, chassisResp] = await Promise.all([
        ajax("/des/admin/scales.json"),
        ajax("/des/admin/chassis-types.json"),
      ]);
      this.scales = scalesResp.scales.map(s => s.name);
      this.chassisTypes = chassisResp.chassis_types.map(c => c.name);
    } catch {
      // fall back to empty if endpoints unavailable
    }
  }

  async loadUserTransponders() {
    try {
      const response = await ajax("/des/transponders.json");
      this.userTransponders = response.transponders;
    } catch {
      this.userTransponders = [];
    }
  }

  resetForm() {
    this.selectedModel = null;
    this.availableModels = [];
    this.showSuggestModel = false;
    this.suggestedManufacturer = null;
    this.suggestModelName = "";
    this.suggestModelYear = "";
    this.suggestModelDriveline = "";
    this.suggestModelScale = "";
    this.suggestModelChassisType = "";
    this.newCarTransponderMode = "registry";
    this.newCarTransponderNew = "";
    this.newCar = {
      manufacturer_id: "", car_model_id: "", class_type_id: "",
      driveline: "", transponder_number: "", friendly_name: "",
    };
    // Auto-select first transponder if available
    if (this.userTransponders.length) {
      this.newCar = { ...this.newCar, transponder_number: this.userTransponders[0].long_code };
    }
  }

  @action
  async selectManufacturer(event) {
    const manufacturerId = event.target.value;
    this.newCar = { ...this.newCar, manufacturer_id: manufacturerId, car_model_id: "" };
    this.selectedModel = null;
    this.showSuggestModel = false;

    if (manufacturerId) {
      try {
        const response = await ajax("/des/garage/models.json", { data: { manufacturer_id: manufacturerId } });
        this.availableModels = response.models || [];
      } catch {
        this.availableModels = [];
      }
    } else {
      this.availableModels = [];
    }
  }

  @action
  selectModel(event) {
    const modelId = event.target.value;
    if (modelId) {
      this.selectedModel = this.availableModels.find(m => m.id === parseInt(modelId));
      this.newCar = { ...this.newCar, car_model_id: modelId, driveline: this.selectedModel?.driveline || "" };
    } else {
      this.selectedModel = null;
      this.newCar = { ...this.newCar, car_model_id: "", driveline: "" };
    }
  }

  @action
  updateField(field, event) {
    this.newCar = { ...this.newCar, [field]: event.target.value };
  }

  @action
  updateSuggestField(field, event) {
    this[field] = event.target.value;
  }

  @action
  toggleSuggestModel() {
    this.showSuggestModel = !this.showSuggestModel;
  }

  @action
  async submitModelAndAddCar() {
    if (!this.suggestModelName) {
      alert("Please enter a model name");
      return;
    }
    if (!this.newCar.transponder_number) {
      alert("Please enter a transponder number");
      return;
    }
    this.isSaving = true;
    try {
      // First submit the model for approval
      const modelResponse = await ajax("/des/garage/suggest-model.json", {
        type: "POST",
        data: {
          manufacturer_id: this.newCar.manufacturer_id,
          name: this.suggestModelName,
          year_released: this.suggestModelYear,
          driveline: this.suggestModelDriveline,
          scale: this.suggestModelScale,
          chassis_type: this.suggestModelChassisType,
        },
      });

      // Then add the car using the pending model
      await ajax("/des/garage.json", {
        type: "POST",
        data: {
          car: {
            ...this.newCar,
            car_model_id: modelResponse.id,
            driveline: this.suggestModelDriveline,
          }
        },
      });

      this.showAddForm = false;
      this.resetForm();
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.isSaving = false;
    }
  }

  @action
  setNewCarTransponderMode(e) {
    this.newCarTransponderMode = e.target.value;
    if (e.target.value !== "new") {
      const t = this.userTransponders.find(t => t.id === parseInt(e.target.value));
      if (t) this.newCar = { ...this.newCar, transponder_number: t.long_code };
    } else {
      this.newCar = { ...this.newCar, transponder_number: "" };
    }
  }

  @action
  updateNewCarTransponderNew(e) {
    this.newCarTransponderNew = e.target.value;
    this.newCar = { ...this.newCar, transponder_number: e.target.value };
  }

  @action
  setEditCarTransponderMode(e) {
    this.editCarTransponderMode = e.target.value;
    if (e.target.value !== "new") {
      const t = this.userTransponders.find(t => t.id === parseInt(e.target.value));
      if (t) this.editingCar = { ...this.editingCar, transponder_number: t.long_code };
    } else {
      this.editingCar = { ...this.editingCar, transponder_number: "" };
    }
  }

  @action
  updateEditCarTransponderNew(e) {
    this.editCarTransponderNew = e.target.value;
    this.editingCar = { ...this.editingCar, transponder_number: e.target.value };
  }

  async maybeRegisterTransponder(code) {
    if (!code || !code.trim()) return;
    const exists = this.userTransponders.find(t => t.long_code === code.trim());
    if (exists) return;
    const nextShortcode = this.userTransponders.length > 0
      ? Math.max(...this.userTransponders.map(t => t.shortcode)) + 1
      : 1;
    const save = window.confirm(`Save ${code.trim()} as transponder #${nextShortcode} in your racing profile?`);
    if (save) {
      try {
        await ajax("/des/transponders.json", {
          type: "POST",
          data: { long_code: code.trim() }
        });
      } catch { /* ignore */ }
    }
  }

  @action
  async saveCar() {
    this.isSaving = true;
    try {
      await ajax("/des/garage.json", {
        type: "POST",
        data: { car: this.newCar },
      });
      if (this.newCarTransponderMode === "new" && this.newCarTransponderNew.trim()) {
        await this.maybeRegisterTransponder(this.newCarTransponderNew);
      }
      this.showAddForm = false;
      this.resetForm();
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.isSaving = false;
    }
  }

  @action
  async removeCar(carId) {
    if (!window.confirm("Remove this car from your garage?")) return;
    try {
      await ajax("/des/garage/" + carId + ".json", { type: "DELETE" });
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  async editCar(car) {
    this.editingCarId = car.id;
    this.editingCar = {
      id: car.id,
      friendly_name: car.friendly_name,
      transponder_number: car.transponder_number,
      manufacturer_id: car.manufacturer?.id,
      car_model_id: car.model?.id,
    };
    this.editModels = [];
    await this.loadUserTransponders();
    // Determine if the current transponder is in the registry
    const match = this.userTransponders.find(t => t.long_code === car.transponder_number);
    if (match) {
      this.editCarTransponderMode = String(match.id);
    } else {
      this.editCarTransponderMode = "new";
      this.editCarTransponderNew = car.transponder_number || "";
    }
    if (car.manufacturer?.id) {
      try {
        const response = await ajax("/des/garage/models.json", { data: { manufacturer_id: car.manufacturer.id } });
        this.editModels = response.models || [];
      } catch { this.editModels = []; }
    }
  }

  @action cancelEditCar() {
    this.editingCarId = null;
    this.editingCar = null;
    this.editModels = [];
  }

  @action
  async editSelectManufacturer(e) {
    const mfrId = e.target.value;
    this.editingCar = { ...this.editingCar, manufacturer_id: mfrId, car_model_id: "" };
    this.editModels = [];
    if (mfrId) {
      try {
        const response = await ajax("/des/garage/models.json", { data: { manufacturer_id: mfrId } });
        this.editModels = response.models || [];
      } catch { this.editModels = []; }
    }
  }

  @action
  updateEditCarField(field, e) {
    this.editingCar = { ...this.editingCar, [field]: e.target.value };
  }

  @action
  async saveEditCar() {
    try {
      await ajax("/des/garage/" + this.editingCar.id + ".json", {
        type: "PUT",
        data: {
          car: {
            manufacturer_id: this.editingCar.manufacturer_id,
            car_model_id: this.editingCar.car_model_id,
            friendly_name: this.editingCar.friendly_name,
            transponder_number: this.editingCar.transponder_number,
          }
        },
      });
      if (this.editCarTransponderMode === "new" && this.editCarTransponderNew.trim()) {
        await this.maybeRegisterTransponder(this.editCarTransponderNew);
      }
      this.editingCarId = null;
      this.editingCar = null;
      this.editModels = [];
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  async suggestManufacturer() {
    const name = window.prompt("Enter manufacturer name:");
    if (!name) return;
    try {
      const response = await ajax("/des/garage/suggest-manufacturer.json", {
        type: "POST",
        data: { name },
      });
      // Set the suggested manufacturer as a pending entry
      this.suggestedManufacturer = { id: response.id, name: response.name, status: response.status };
      this.newCar = { ...this.newCar, manufacturer_id: response.id };
      // Automatically show the suggest model form
      this.showSuggestModel = true;
    } catch (error) {
      popupAjaxError(error);
    }
  }
}
