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
  chassisTypes = ["1/10 Buggy", "1/10 Stadium", "1/10 Short Course", "1/10 Truggy", "1/8 Buggy", "1/8 Truggy", "1/10 Rally", "Other"];

  @action
  setTab(tab) {
    this.activeTab = tab;
  }

  @tracked newModel = { manufacturer_id: "", name: "", year_released: "", driveline: "", chassis_type: "" };
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
      this.newModel = { manufacturer_id: "", name: "", year_released: "", driveline: "", chassis_type: "" };
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
  setTabModels() { this.activeTab = "models"; }

  @action
  setTabRules() { this.activeTab = "rules"; }



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

  @action
  async addGlobalRule() {
    const classTypeId = document.getElementById('new-rule-class-type').value;
    const ruleType = document.getElementById('new-rule-type').value;
    const ruleValue = document.getElementById('new-rule-value').value.trim();

    if (!classTypeId || !ruleValue) {
      alert("Please select a class type and enter a rule value.");
      return;
    }

    try {
      await ajax("/des/admin/rules.json", {
        type: "POST",
        data: { class_type_id: classTypeId, rule_type: ruleType, rule_value: ruleValue },
      });
      document.getElementById('new-rule-class-type').value = '';
      document.getElementById('new-rule-value').value = '';
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

    const chassisOptions = [
      "1/8 Buggy", "1/8 Truck",
      "1/10 Buggy", "1/10 Stadium", "1/10 Short course",
      "1/10 Touring Car", "1/10 Rally", "1/10 Pan car",
      "1/12 Pan car", "1/28 Touring car", "1/28 Buggy", "1/28 Truck"
    ];
    const chassisChoice = window.prompt(
      "Chassis type for " + model.manufacturer + " " + model.name + ":\n\n" +
      chassisOptions.map((c, i) => (i+1) + " = " + c).join("\n") +
      "\n\nEnter number (1-12):",
      model.chassis_type ? (chassisOptions.indexOf(model.chassis_type) + 1).toString() : "3"
    );
    if (chassisChoice === null) return;
    const chassisType = chassisOptions[parseInt(chassisChoice) - 1];
    if (!chassisType) {
      alert("Invalid chassis selection. Please enter a number between 1 and 12.");
      return;
    }

    try {
      await ajax("/des/admin/models/" + model.id + "/approve.json", {
        type: "POST",
        data: { year_released: year, driveline: driveline, chassis_type: chassisType },
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
    this.editingModel = { ...this.editingModel, [field]: e.target.value };
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
}
