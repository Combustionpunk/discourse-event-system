import Controller from "@ember/controller";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default class CarModelsController extends Controller {
  @service currentUser;
  @service router;

  @tracked showSuggestManufacturer = false;
  @tracked showAddManufacturer = false;
  @tracked newManufacturerName = "";
  @tracked approvingModelId = null;
  @tracked approveModelForm = { year_released: "", driveline: "", scale: "", chassis_type: "" };
  @tracked editingModelId = null;
  @tracked editModelForm = { name: "", year_released: "", driveline: "", scale: "", chassis_type: "" };
  @tracked addingModelForManufacturerId = null;
  @tracked newModelForm = { name: "", year_released: "", driveline: "", scale: "", chassis_type: "" };
  @tracked scales = [];
  @tracked chassisTypes = [];

  constructor() {
    super(...arguments);
    this.loadScalesAndChassisTypes();
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
      // fall back to empty
    }
  }

  get approvedManufacturers() {
    return (this.model.manufacturers || []).filter(m => m.status === "approved");
  }

  get pendingManufacturers() {
    return (this.model.manufacturers || []).filter(m => m.status === "pending");
  }

  @action
  toggleSuggestManufacturer() {
    this.showSuggestManufacturer = !this.showSuggestManufacturer;
    this.newManufacturerName = "";
  }

  @action
  toggleAddManufacturer() {
    this.showAddManufacturer = !this.showAddManufacturer;
    this.newManufacturerName = "";
  }

  @action
  updateNewManufacturerName(e) {
    this.newManufacturerName = e.target.value;
  }

  @action
  async suggestManufacturer() {
    if (!this.newManufacturerName.trim()) return;
    try {
      await ajax("/des/car-models/suggest-manufacturer.json", {
        type: "POST",
        data: { name: this.newManufacturerName.trim() }
      });
      this.showSuggestManufacturer = false;
      this.newManufacturerName = "";
      this.router.refresh();
    } catch (error) { popupAjaxError(error); }
  }

  @action
  async addManufacturer() {
    if (!this.newManufacturerName.trim()) return;
    try {
      await ajax("/des/admin/manufacturers.json", {
        type: "POST",
        data: { name: this.newManufacturerName.trim() }
      });
      this.showAddManufacturer = false;
      this.newManufacturerName = "";
      this.router.refresh();
    } catch (error) { popupAjaxError(error); }
  }

  @action
  async approveManufacturer(mfr) {
    try {
      await ajax(`/des/admin/manufacturers/${mfr.id}/approve.json`, { type: "POST" });
      this.router.refresh();
    } catch (error) { popupAjaxError(error); }
  }

  @action
  async rejectManufacturer(mfr) {
    if (!window.confirm(`Reject manufacturer "${mfr.name}"?`)) return;
    try {
      await ajax(`/des/admin/manufacturers/${mfr.id}.json`, { type: "DELETE" });
      this.router.refresh();
    } catch (error) { popupAjaxError(error); }
  }

  @tracked editingManufacturerId = null;
  @tracked editManufacturerName = "";
  @tracked editManufacturerLogoUploadId = null;
  @tracked editManufacturerLogoUrl = null;

  @action
  startEditManufacturer(mfr) {
    this.editingManufacturerId = mfr.id;
    this.editManufacturerName = mfr.name;
    this.editManufacturerLogoUploadId = mfr.logo_upload_id || null;
    this.editManufacturerLogoUrl = mfr.logo_url || null;
  }

  @action
  cancelEditManufacturer() {
    this.editingManufacturerId = null;
    this.editManufacturerName = "";
    this.editManufacturerLogoUploadId = null;
    this.editManufacturerLogoUrl = null;
  }

  @action
  updateEditManufacturerName(e) {
    this.editManufacturerName = e.target.value;
  }

  @action
  manufacturerLogoUploaded(upload) {
    this.editManufacturerLogoUploadId = upload.id;
    this.editManufacturerLogoUrl = upload.url;
  }

  @action
  removeManufacturerLogo() {
    this.editManufacturerLogoUploadId = null;
    this.editManufacturerLogoUrl = null;
  }

  @action
  async saveEditManufacturer() {
    if (!this.editManufacturerName.trim()) return;
    try {
      await ajax(`/des/admin/manufacturers/${this.editingManufacturerId}.json`, {
        type: "PUT",
        data: {
          name: this.editManufacturerName.trim(),
          logo_upload_id: this.editManufacturerLogoUploadId
        }
      });
      this.editingManufacturerId = null;
      this.router.refresh();
    } catch (error) { popupAjaxError(error); }
  }

  @action
  startAddModel(manufacturerId) {
    this.addingModelForManufacturerId = manufacturerId;
    this.newModelForm = { name: "", year_released: "", driveline: "", scale: "", chassis_type: "" };
  }

  @action
  cancelAddModel() {
    this.addingModelForManufacturerId = null;
  }

  @action
  updateNewModelField(field, e) {
    this.newModelForm = { ...this.newModelForm, [field]: e.target.value };
  }

  @action
  async confirmAddModel() {
    if (!this.newModelForm.name.trim()) return;
    try {
      await ajax("/des/admin/models.json", {
        type: "POST",
        data: { ...this.newModelForm, manufacturer_id: this.addingModelForManufacturerId }
      });
      this.addingModelForManufacturerId = null;
      this.router.refresh();
    } catch (error) { popupAjaxError(error); }
  }

  @action
  startApproveModel(model) {
    this.approvingModelId = model.id;
    this.approveModelForm = {
      year_released: model.year_released || "",
      driveline: model.driveline || "",
      scale: model.scale || "",
      chassis_type: model.chassis_type || ""
    };
  }

  @action
  cancelApproveModel() {
    this.approvingModelId = null;
  }

  @action
  updateApproveField(field, e) {
    this.approveModelForm = { ...this.approveModelForm, [field]: e.target.value };
  }

  @action
  async confirmApproveModel() {
    try {
      await ajax(`/des/admin/models/${this.approvingModelId}/approve.json`, {
        type: "POST",
        data: this.approveModelForm
      });
      this.approvingModelId = null;
      this.router.refresh();
    } catch (error) { popupAjaxError(error); }
  }

  @action
  async rejectModel(model) {
    if (!window.confirm(`Reject model "${model.name}"?`)) return;
    try {
      await ajax(`/des/admin/models/${model.id}.json`, { type: "DELETE" });
      this.router.refresh();
    } catch (error) { popupAjaxError(error); }
  }

  @action
  startEditModel(model) {
    this.editingModelId = model.id;
    this.editModelForm = {
      name: model.name,
      year_released: model.year_released || "",
      driveline: model.driveline || "",
      scale: model.scale || "",
      chassis_type: model.chassis_type || ""
    };
  }

  @action
  cancelEditModel() {
    this.editingModelId = null;
  }

  @action
  updateEditModelField(field, e) {
    this.editModelForm = { ...this.editModelForm, [field]: e.target.value };
  }

  @action
  async saveEditModel() {
    try {
      await ajax(`/des/admin/models/${this.editingModelId}.json`, {
        type: "PUT",
        data: this.editModelForm
      });
      this.editingModelId = null;
      this.router.refresh();
    } catch (error) { popupAjaxError(error); }
  }

  @action
  async deleteModel(model) {
    if (!window.confirm(`Delete model "${model.name}"?`)) return;
    try {
      await ajax(`/des/admin/models/${model.id}.json`, { type: "DELETE" });
      this.router.refresh();
    } catch (error) { popupAjaxError(error); }
  }

  @action
  addToGarage(model) {
    this.router.transitionTo("my-garage", {
      queryParams: {
        manufacturer_id: String(model.manufacturer_id),
        model_id: String(model.id)
      }
    });
  }
}
