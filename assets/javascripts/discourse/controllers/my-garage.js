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
  chassisTypes = ["1/10 Buggy", "1/10 Stadium", "1/10 Short Course", "1/10 Truggy", "1/8 Buggy", "1/8 Truggy", "1/10 Rally", "Other"];
  @tracked suggestModelChassisType = "";

  @action
  toggleAddForm() {
    this.showAddForm = !this.showAddForm;
    this.resetForm();
  }

  resetForm() {
    this.selectedModel = null;
    this.availableModels = [];
    this.showSuggestModel = false;
    this.suggestedManufacturer = null;
    this.suggestModelName = "";
    this.suggestModelYear = "";
    this.suggestModelDriveline = "";
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
        const response = await ajax("/des/garage/models.json?manufacturer_id=" + manufacturerId);
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
