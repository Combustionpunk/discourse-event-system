import Controller from "@ember/controller";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { inject as service } from "@ember/service";

export default class DesAdminController extends Controller {
  @service router;
  @tracked activeTab = "organisations";
  drivelines = ["2WD", "4WD", "FWD", "Rear Motor"];
  @tracked scales = [];
  @tracked chassisTypes = [];
  @tracked scalesList = [];
  @tracked chassisTypesList = [];
  @tracked newScaleName = "";
  @tracked newChassisTypeName = "";

  @action
  setTab(tab) {
    this.activeTab = tab;
  }

  @tracked newModel = { manufacturer_id: "", name: "", year_released: "", driveline: "", scale: "", chassis_type: "" };
  @tracked showAddModelForm = false;

  @action
  toggleAddModelForm() {
    this.showAddModelForm = !this.showAddModelForm;
  }

  @action
  updateNewModel(field, e) {
    this.newModel = { ...this.newModel, [field]: e.target.value };
  }

  @action
  async createModel() {
    if (!this.newModel.manufacturer_id || !this.newModel.name) {
      alert("Please select a manufacturer and enter a model name");
      return;
    }
    try {
      await ajax("/des/admin/models.json", {
        type: "POST",
        data: this.newModel,
      });
      this.newModel = { manufacturer_id: "", name: "", year_released: "", driveline: "", scale: "", chassis_type: "" };
      this.showAddModelForm = false;
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  setTabOrganisations() { this.activeTab = "organisations"; }

  @action
  setTabManufacturers() { this.activeTab = "manufacturers"; }

  @action
  async setTabModels() {
    this.activeTab = "models";
    await this.loadScalesAndChassisTypes();
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

  @action
  async setTabRules() { this.activeTab = "rules"; await this.loadScalesAndChassisTypes(); }
  @action
  setTabCleanup() { this.activeTab = "cleanup"; this.loadOrphanedCars(); }

  @tracked adminVenues = [];

  @action
  setTabVenues() { this.activeTab = "venues"; this.loadAdminVenues(); }

  async loadAdminVenues() {
    try {
      const response = await ajax("/des/admin/venues.json");
      this.adminVenues = response.venues || [];
    } catch { this.adminVenues = []; }
  }

  @action
  async approveVenue(venue) {
    try {
      await ajax("/des/admin/venues/" + venue.id + "/approve.json", { type: "PUT" });
      this.loadAdminVenues();
    } catch (error) { popupAjaxError(error); }
  }

  @action
  async deleteVenue(venue) {
    if (!window.confirm("Delete " + venue.name + "?")) return;
    try {
      await ajax("/des/venues/" + venue.id + ".json", { type: "DELETE" });
      this.loadAdminVenues();
    } catch (error) { popupAjaxError(error); }
  }

  @action
  async setTabScales() {
    this.activeTab = "scales";
    try {
      const response = await ajax("/des/admin/scales.json");
      this.scalesList = response.scales;
    } catch { this.scalesList = []; }
  }

  @action
  async setTabChassisTypes() {
    this.activeTab = "chassis_types";
    try {
      const response = await ajax("/des/admin/chassis-types.json");
      this.chassisTypesList = response.chassis_types;
    } catch { this.chassisTypesList = []; }
  }

  @action
  updateAdminField(field, e) {
    this[field] = e.target.value;
  }

  @action
  async addScale() {
    if (!this.newScaleName.trim()) return;
    try {
      const scale = await ajax("/des/admin/scales.json", { type: "POST", data: { name: this.newScaleName.trim() } });
      this.scalesList = [...this.scalesList, scale];
      this.newScaleName = "";
    } catch (error) { popupAjaxError(error); }
  }

  @action
  async deleteScale(scale) {
    if (!window.confirm(`Delete scale "${scale.name}"?`)) return;
    try {
      await ajax(`/des/admin/scales/${scale.id}.json`, { type: "DELETE" });
      this.scalesList = this.scalesList.filter(s => s.id !== scale.id);
    } catch (error) { popupAjaxError(error); }
  }

  @action
  async addChassisType() {
    if (!this.newChassisTypeName.trim()) return;
    try {
      const ct = await ajax("/des/admin/chassis-types.json", { type: "POST", data: { name: this.newChassisTypeName.trim() } });
      this.chassisTypesList = [...this.chassisTypesList, ct];
      this.newChassisTypeName = "";
    } catch (error) { popupAjaxError(error); }
  }

  @action
  async deleteChassisType(ct) {
    if (!window.confirm(`Delete chassis type "${ct.name}"?`)) return;
    try {
      await ajax(`/des/admin/chassis-types/${ct.id}.json`, { type: "DELETE" });
      this.chassisTypesList = this.chassisTypesList.filter(c => c.id !== ct.id);
    } catch (error) { popupAjaxError(error); }
  }

  @action
  async approveOrganisation(org) {
    const surcharge = window.prompt(
      "Set surcharge percentage for " + org.name + ":",
      "5"
    );
    if (surcharge === null) return;
    try {
      await ajax("/des/admin/organisations/" + org.id + "/approve.json", {
        type: "POST",
        data: { surcharge_percentage: parseFloat(surcharge) },
      });
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  async rejectOrganisation(org) {
    const reason = window.prompt("Reason for rejecting " + org.name + ":");
    if (reason === null) return;
    try {
      await ajax("/des/admin/organisations/" + org.id + "/reject.json", {
        type: "POST",
        data: { reason },
      });
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  async approveManufacturer(manufacturer) {
    try {
      await ajax("/des/admin/manufacturers/" + manufacturer.id + "/approve.json", {
        type: "POST",
      });
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  async rejectManufacturer(manufacturer) {
    try {
      await ajax("/des/admin/manufacturers/" + manufacturer.id + "/reject.json", {
        type: "POST",
      });
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @tracked editingManufacturerId = null;
  @tracked editingManufacturerName = "";

  @action
  startEditManufacturer(manufacturer) {
    this.editingManufacturerId = manufacturer.id;
    this.editingManufacturerName = manufacturer.name;
  }

  @action
  cancelEditManufacturer() {
    this.editingManufacturerId = null;
    this.editingManufacturerName = "";
  }

  @action
  updateEditingManufacturerName(e) {
    this.editingManufacturerName = e.target.value;
  }

  @action
  async saveManufacturer() {
    if (!this.editingManufacturerName.trim()) return;
    try {
      await ajax("/des/admin/manufacturers/" + this.editingManufacturerId + ".json", {
        type: "PUT",
        data: { name: this.editingManufacturerName },
      });
      this.editingManufacturerId = null;
      this.editingManufacturerName = "";
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  async deleteManufacturer(manufacturer) {
    if (!window.confirm(`Delete ${manufacturer.name}? This will also affect any car models linked to this manufacturer.`)) return;
    try {
      await ajax("/des/admin/manufacturers/" + manufacturer.id + ".json", {
        type: "DELETE",
      });
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @tracked orphanedCars = [];
  @tracked editingOrphanCarId = null;
  @tracked editingOrphanMfr = null;
  @tracked editingOrphanModel = null;
  @tracked orphanModels = [];

  async loadOrphanedCars() {
    try {
      const response = await ajax("/des/admin/orphaned-cars.json");
      this.orphanedCars = response.cars || [];
    } catch {
      this.orphanedCars = [];
    }
  }

  @action
  async deleteModel(model) {
    if (!window.confirm(`Delete ${model.name}? Cars using this model will lose their model reference.`)) return;
    try {
      await ajax("/des/admin/models/" + model.id + ".json", { type: "DELETE" });
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  startEditOrphanCar(car) {
    this.editingOrphanCarId = car.id;
    this.editingOrphanMfr = car.manufacturer_id;
    this.editingOrphanModel = car.car_model_id;
    this.orphanModels = [];
    if (car.manufacturer_id) this.loadOrphanModels(car.manufacturer_id);
  }

  @action
  cancelEditOrphanCar() {
    this.editingOrphanCarId = null;
  }

  @action
  async updateOrphanMfr(e) {
    this.editingOrphanMfr = parseInt(e.target.value, 10);
    this.editingOrphanModel = null;
    if (this.editingOrphanMfr) {
      await this.loadOrphanModels(this.editingOrphanMfr);
    } else {
      this.orphanModels = [];
    }
  }

  async loadOrphanModels(mfrId) {
    try {
      const response = await ajax("/des/garage/models.json", { data: { manufacturer_id: mfrId } });
      this.orphanModels = response.models || [];
    } catch {
      this.orphanModels = [];
    }
  }

  @action
  updateOrphanModel(e) {
    this.editingOrphanModel = parseInt(e.target.value, 10);
  }

  @action
  async saveOrphanCar(car) {
    try {
      await ajax("/des/admin/cars/" + car.id + ".json", {
        type: "PUT",
        data: {
          manufacturer_id: this.editingOrphanMfr,
          car_model_id: this.editingOrphanModel,
        },
      });
      this.editingOrphanCarId = null;
      this.loadOrphanedCars();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  async deleteOrphanCar(car) {
    if (!window.confirm(`Delete ${car.friendly_name} (owned by ${car.username})?`)) return;
    try {
      await ajax("/des/admin/cars/" + car.id + ".json", { type: "DELETE" });
      this.loadOrphanedCars();
    } catch (error) {
      popupAjaxError(error);
    }
  }



  ruleTypeLabel(ruleType) {
    const labels = {
      driveline: 'Driveline',
      chassis: 'Chassis',
      manufacturer: 'Manufacturer',
      max_year: 'Max Year',
      min_year: 'Min Year',
      max_age: 'Max Age',
      min_age: 'Min Age',
      model: 'Model'
    };
    return labels[ruleType] || ruleType;
  }

  get groupedGlobalRules() {
    const rules = this.model.global_rules || [];
    const groups = {};
    rules.forEach(rule => {
      if (!groups[rule.class_type_id]) {
        groups[rule.class_type_id] = {
          class_type_name: rule.class_type_name,
          rules: []
        };
      }
      groups[rule.class_type_id].rules.push(rule);
    });
    return Object.values(groups);
  }

  @tracked newRuleType = "max_year";
  @tracked newRuleValue = "";

  @action
  updateRuleType(e) {
    this.newRuleType = e.target.value;
    this.newRuleValue = "";
  }

  @action
  updateRuleValueMulti(e) {
    const selected = Array.from(e.target.selectedOptions).map(o => o.value);
    this.newRuleValue = selected.join(',');
  }

  @action
  updateRuleValueText(e) {
    this.newRuleValue = e.target.value;
  }

  @action
  async addGlobalRule() {
    const classTypeId = document.getElementById('new-rule-class-type').value;
    const ruleValue = this.newRuleValue.trim();

    if (!classTypeId || !ruleValue) {
      alert("Please select a class type and enter a rule value.");
      return;
    }

    try {
      await ajax("/des/admin/rules.json", {
        type: "POST",
        data: { class_type_id: classTypeId, rule_type: this.newRuleType, rule_value: ruleValue },
      });
      document.getElementById('new-rule-class-type').value = '';
      this.newRuleType = "max_year";
      this.newRuleValue = "";
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  async deleteGlobalRule(ruleId) {
    if (!window.confirm("Delete this rule?")) return;
    try {
      await ajax("/des/admin/rules/" + ruleId + ".json", { type: "DELETE" });
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  async approveModel(model) {
    const year = window.prompt(
      "Year of first manufacture for " + model.manufacturer + " " + model.name + ":",
      model.year_released || ""
    );
    if (year === null) return;

    const drivelineOptions = ["2WD", "4WD", "FWD", "Rear Motor"];
    const drivelineChoice = window.prompt(
      "Driveline for " + model.manufacturer + " " + model.name + ":\n\n" +
      "Enter number:\n1 = 2WD\n2 = 4WD\n3 = FWD\n4 = Rear Motor",
      "1"
    );
    if (drivelineChoice === null) return;
    const driveline = drivelineOptions[parseInt(drivelineChoice) - 1];
    if (!driveline) {
      alert("Invalid selection. Please enter 1, 2, 3 or 4.");
      return;
    }

    const scaleOptions = this.scales.length ? this.scales : ["1/8", "1/10", "1/12", "1/28"];
    const scaleChoice = window.prompt(
      "Scale for " + model.manufacturer + " " + model.name + ":\n\n" +
      scaleOptions.map((s, i) => (i+1) + " = " + s).join("\n") +
      "\n\nEnter number (1-4):",
      model.scale ? (scaleOptions.indexOf(model.scale) + 1).toString() : "2"
    );
    if (scaleChoice === null) return;
    const scale = scaleOptions[parseInt(scaleChoice) - 1];
    if (!scale) {
      alert("Invalid scale selection. Please enter a number between 1 and 4.");
      return;
    }

    const chassisOptions = this.chassisTypes.length ? this.chassisTypes : [
      "Buggy", "Truck", "Stadium", "Short Course",
      "Touring Car", "Rally", "Pan Car", "Drift"
    ];
    const chassisChoice = window.prompt(
      "Chassis type for " + model.manufacturer + " " + model.name + ":\n\n" +
      chassisOptions.map((c, i) => (i+1) + " = " + c).join("\n") +
      "\n\nEnter number (1-8):",
      model.chassis_type ? (chassisOptions.indexOf(model.chassis_type) + 1).toString() : "1"
    );
    if (chassisChoice === null) return;
    const chassisType = chassisOptions[parseInt(chassisChoice) - 1];
    if (!chassisType) {
      alert("Invalid chassis selection. Please enter a number between 1 and 8.");
      return;
    }

    try {
      await ajax("/des/admin/models/" + model.id + "/approve.json", {
        type: "POST",
        data: { year_released: year, driveline: driveline, scale: scale, chassis_type: chassisType },
      });
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  async rejectModel(model) {
    try {
      await ajax("/des/admin/models/" + model.id + "/reject.json", {
        type: "POST",
      });
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    }
  }


  @tracked editingModelId = null;
  @tracked editingModel = null;

  @action
  editModel(model) {
    this.editingModelId = model.id;
    this.editingModel = { ...model };
  }

  @action
  updateEditField(field, e) {
    const val = field === "manufacturer_id" ? parseInt(e.target.value, 10) : e.target.value;
    this.editingModel = { ...this.editingModel, [field]: val };
  }

  @action
  cancelEdit() {
    this.editingModelId = null;
    this.editingModel = null;
  }

  @action
  async saveModel() {
    try {
      await ajax("/des/admin/models/" + this.editingModel.id + ".json", {
        type: "PUT",
        data: {
          manufacturer_id: this.editingModel.manufacturer_id,
          name: this.editingModel.name,
          year_released: this.editingModel.year_released,
          driveline: this.editingModel.driveline,
          scale: this.editingModel.scale,
          chassis_type: this.editingModel.chassis_type,
        },
      });
      this.editingModelId = null;
      this.editingModel = null;
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  // Class Type management
  @tracked showAddClassTypeForm = false;

  @action
  toggleAddClassTypeForm() {
    this.showAddClassTypeForm = !this.showAddClassTypeForm;
  }

  @action
  async createClassType(formData) {
    await ajax("/des/admin/class-types.json", {
      type: "POST",
      data: {
        name: formData.name,
        track_environment: formData.track_environment || null,
        scale: formData.scale || null,
        chassis_types: formData.chassis_types,
        drivelines: formData.drivelines,
        min_year: formData.min_year || null,
        max_year: formData.max_year || null,
        manufacturer: formData.manufacturer || null,
        model_id: formData.model_id || null,
        min_age: formData.min_age || null,
        max_age: formData.max_age || null,
      },
    });
    this.showAddClassTypeForm = false;
    this.router.refresh();
  }

  @action
  async deleteClassType(ct) {
    if (!window.confirm(`Delete class type "${ct.name}"?`)) return;
    try {
      await ajax(`/des/admin/class-types/${ct.id}.json`, { type: "DELETE" });
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    }
  }
}
