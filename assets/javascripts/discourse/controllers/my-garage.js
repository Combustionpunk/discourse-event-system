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

  @action
  async toggleAddForm() {
    this.showAddForm = !this.showAddForm;
    this.resetForm();
    if (this.showAddForm) {
      await this.loadScalesAndChassisTypes();
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
    this.newCar = {
      manufacturer_id: "", car_model_id: "", class_type_id: "",
      driveline: "", transponder_number: "", friendly_name: "",
    };
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
  async saveCar() {
    this.isSaving = true;
    try {
      await ajax("/des/garage.json", {
        type: "POST",
        data: { car: this.newCar },
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
