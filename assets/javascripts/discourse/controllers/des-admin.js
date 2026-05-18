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
  @tracked pendingSuggestions = [];
  @tracked resolvedSuggestions = [];
  @tracked suggestionsLoading = false;
  @tracked mergeKeepId = null;
  @tracked mergeDuplicateId = null;

  get pendingSuggestionsCount() {
    return this.pendingSuggestions.length;
  }

  @action
  setTab(tab) {
    this.activeTab = tab;
  }

  @action
  async setTabSuggestions() {
    this.activeTab = "suggestions";
    this.suggestionsLoading = true;
    try {
      const response = await ajax("/des/admin/venue-suggestions.json");
      this.pendingSuggestions = response.pending || [];
      this.resolvedSuggestions = response.resolved || [];
    } catch { /* ignore */ } finally {
      this.suggestionsLoading = false;
    }
  }

  formatSuggestion(data) {
    if (!data) return "No data";
    return Object.entries(data)
      .filter(([, v]) => v !== "" && v !== null && v !== undefined)
      .map(([k, v]) => {
        if (typeof v === 'object') return `${k}: ${JSON.stringify(v)}`;
        return `${k}: ${v}`;
      })
      .join("\n");
  }

  @action
  async approveSuggestion(suggestion) {
    if (!window.confirm(`Approve suggestion for "${suggestion.venue_name}"? This will update the venue.`)) return;
    try {
      await ajax(`/des/admin/venue-suggestions/${suggestion.id}/approve.json`, { type: "PUT" });
      this.pendingSuggestions = this.pendingSuggestions.filter(s => s.id !== suggestion.id);
      this.resolvedSuggestions = [{ ...suggestion, status: 'approved' }, ...this.resolvedSuggestions];
    } catch (error) { popupAjaxError(error); }
  }

  @action
  async rejectSuggestion(suggestion) {
    const notes = window.prompt("Optional rejection note:");
    try {
      await ajax(`/des/admin/venue-suggestions/${suggestion.id}/reject.json`, { type: "PUT", data: { admin_notes: notes || "" } });
      this.pendingSuggestions = this.pendingSuggestions.filter(s => s.id !== suggestion.id);
      this.resolvedSuggestions = [{ ...suggestion, status: 'rejected', admin_notes: notes }, ...this.resolvedSuggestions];
    } catch (error) { popupAjaxError(error); }
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
  @tracked showAddVenueForm = false;
  @tracked isGeocoding = false;
  @tracked geocodeResult = null;
  @tracked adminPayouts = [];
  @tracked adminPayoutSummary = null;
  @tracked adminPayoutsLoading = false;
  @tracked payoutPeriod = "all";
  @tracked approvingPayoutId = null;

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
  async approveVenueClaim(venue) {
    if (!window.confirm(`Approve claim of "${venue.name}" by ${venue.claimed_organisation_name}?`)) return;
    try {
      await ajax(`/des/admin/venues/${venue.id}/approve-claim.json`, { type: "PUT" });
      this.loadAdminVenues();
    } catch (error) { popupAjaxError(error); }
  }

  @action
  async rejectVenueClaim(venue) {
    try {
      await ajax(`/des/admin/venues/${venue.id}/reject-claim.json`, { type: "PUT" });
      this.loadAdminVenues();
    } catch (error) { popupAjaxError(error); }
  }

  get cannotMerge() {
    return !this.mergeKeepId || !this.mergeDuplicateId || this.mergeKeepId === this.mergeDuplicateId;
  }

  @action updateMergeKeep(e) { this.mergeKeepId = parseInt(e.target.value) || null; }
  @action updateMergeDuplicate(e) { this.mergeDuplicateId = parseInt(e.target.value) || null; }

  @action
  async mergeVenues() {
    const keep = this.adminVenues.find(v => v.id === this.mergeKeepId);
    const dupe = this.adminVenues.find(v => v.id === this.mergeDuplicateId);
    if (!keep || !dupe) return;
    if (!window.confirm(`Merge "${dupe.name}" INTO "${keep.name}"?\n\nThis will permanently delete "${dupe.name}" and re-link all its events to "${keep.name}". This cannot be undone.`)) return;
    try {
      await ajax('/des/admin/venues/merge.json', {
        type: 'POST',
        data: { keep_id: this.mergeKeepId, merge_id: this.mergeDuplicateId }
      });
      this.mergeKeepId = null;
      this.mergeDuplicateId = null;
      await this.loadAdminVenues();
    } catch (error) { popupAjaxError(error); }
  }

  @action
  toggleAddVenueForm() {
    this.showAddVenueForm = !this.showAddVenueForm;
  }

  @action
  async createAdminVenue(formData) {
    await ajax("/des/venues.json", {
      type: "POST",
      data: formData
    });
    this.showAddVenueForm = false;
    this.loadAdminVenues();
  }

  @action
  async geocodeAllVenues() {
    this.isGeocoding = true;
    this.geocodeResult = null;
    try {
      const response = await ajax("/des/admin/venues/geocode-all.json", { type: "POST" });
      this.geocodeResult = `✅ Queued ${response.queued} venue${response.queued !== 1 ? 's' : ''} for geocoding`;
    } catch {
      this.geocodeResult = "❌ Failed to queue geocoding";
    } finally {
      this.isGeocoding = false;
    }
  }

  @action
  setTabPayouts() {
    this.activeTab = "payouts";
    this.loadAdminPayouts();
  }

  @action
  async setPayoutPeriod(period) {
    this.payoutPeriod = period;
    await this.loadAdminPayouts();
  }

  async loadAdminPayouts() {
    this.adminPayoutsLoading = true;
    try {
      const response = await ajax("/des/admin/payouts.json", {
        data: this.payoutPeriod !== 'all' ? { period: this.payoutPeriod } : {}
      });
      this.adminPayouts = response.payouts || [];
      this.adminPayoutSummary = response.summary || null;
    } catch {
      // silent
    } finally {
      this.adminPayoutsLoading = false;
    }
  }

  @action
  async adminApprovePayout(payout) {
    if (!window.confirm(`Approve payout of £${payout.net_amount} for ${payout.organisation_name} — ${payout.event_title}?\n\nThis will notify the organisation that they can claim their funds.`)) return;
    this.approvingPayoutId = payout.event_id;
    try {
      await ajax(`/des/events/${payout.event_id}/payout/approve.json`, { type: "POST" });
      await this.loadAdminPayouts();
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.approvingPayoutId = null;
    }
  }

  @tracked editingVenueId = null;

  @action
  startEditVenue(venue) {
    this.editingVenueId = venue.id;
  }

  @action
  cancelEditVenue() {
    this.editingVenueId = null;
  }

  @action
  async saveEditVenue(formData) {
    try {
      await ajax(`/des/venues/${this.editingVenueId}.json`, {
        type: "PUT",
        data: formData
      });
      this.editingVenueId = null;
      this.loadAdminVenues();
    } catch (error) {
      popupAjaxError(error);
    }
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
  @tracked editingManufacturerLogoUploadId = null;
  @tracked editingManufacturerLogoUrl = null;
  @tracked showAddManufacturerForm = false;
  @tracked newManufacturerName = "";

  @action
  startEditManufacturer(manufacturer) {
    this.editingManufacturerId = manufacturer.id;
    this.editingManufacturerName = manufacturer.name;
    this.editingManufacturerLogoUploadId = manufacturer.logo_upload_id || null;
    this.editingManufacturerLogoUrl = manufacturer.logo_url || null;
  }

  @action
  cancelEditManufacturer() {
    this.editingManufacturerId = null;
    this.editingManufacturerName = "";
    this.editingManufacturerLogoUploadId = null;
    this.editingManufacturerLogoUrl = null;
  }

  @action
  updateEditingManufacturerName(e) {
    this.editingManufacturerName = e.target.value;
  }

  @action
  manufacturerLogoUploaded(upload) {
    this.editingManufacturerLogoUploadId = upload.id;
    this.editingManufacturerLogoUrl = upload.url;
  }

  @action
  removeManufacturerLogo() {
    this.editingManufacturerLogoUploadId = null;
    this.editingManufacturerLogoUrl = null;
  }

  @action
  async saveManufacturer() {
    if (!this.editingManufacturerName.trim()) return;
    try {
      await ajax("/des/admin/manufacturers/" + this.editingManufacturerId + ".json", {
        type: "PUT",
        data: {
          name: this.editingManufacturerName,
          logo_upload_id: this.editingManufacturerLogoUploadId
        },
      });
      this.editingManufacturerId = null;
      this.editingManufacturerName = "";
      this.editingManufacturerLogoUploadId = null;
      this.editingManufacturerLogoUrl = null;
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  toggleAddManufacturerForm() {
    this.showAddManufacturerForm = !this.showAddManufacturerForm;
    this.newManufacturerName = "";
  }

  @action
  updateNewManufacturerName(e) {
    this.newManufacturerName = e.target.value;
  }

  @action
  async addManufacturer() {
    if (!this.newManufacturerName.trim()) return;
    try {
      await ajax("/des/admin/manufacturers.json", {
        type: "POST",
        data: { name: this.newManufacturerName.trim() }
      });
      this.showAddManufacturerForm = false;
      this.newManufacturerName = "";
      this.router.refresh();
    } catch (error) { popupAjaxError(error); }
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

  @tracked approvingModelId = null;
  @tracked approveModelForm = { year_released: "", driveline: "", scale: "", chassis_type: "" };

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
    this.approveModelForm = { year_released: "", driveline: "", scale: "", chassis_type: "" };
  }

  @action
  updateApproveField(field, e) {
    this.approveModelForm = { ...this.approveModelForm, [field]: e.target.value };
  }

  @action
  async confirmApproveModel() {
    try {
      await ajax("/des/admin/models/" + this.approvingModelId + "/approve.json", {
        type: "POST",
        data: {
          year_released: this.approveModelForm.year_released,
          driveline: this.approveModelForm.driveline,
          scale: this.approveModelForm.scale,
          chassis_type: this.approveModelForm.chassis_type,
        },
      });
      this.approvingModelId = null;
      this.approveModelForm = { year_released: "", driveline: "", scale: "", chassis_type: "" };
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

  @tracked editingClassTypeId = null;
  @tracked expandedOrgGroups = [];

  @action
  toggleOrgClassGroup(orgId) {
    if (this.expandedOrgGroups.includes(orgId)) {
      this.expandedOrgGroups = this.expandedOrgGroups.filter(id => id !== orgId);
    } else {
      this.expandedOrgGroups = [...this.expandedOrgGroups, orgId];
    }
  }

  @action
  startEditClassType(ct) {
    this.editingClassTypeId = ct.id;
  }

  @action
  cancelEditClassType() {
    this.editingClassTypeId = null;
  }

  @action
  async saveEditClassType(formData) {
    await ajax(`/des/admin/class-types/${this.editingClassTypeId}.json`, {
      type: "PUT",
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
    this.editingClassTypeId = null;
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

  @action
  async deleteEvent(event) {
    if (!window.confirm(`Permanently delete "${event.title}"? This cannot be undone. All bookings will be cancelled.`)) return;
    try {
      await ajax(`/des/admin/events/${event.id}.json`, { type: "DELETE" });
      this.router.refresh();
    } catch (error) { popupAjaxError(error); }
  }

  @action
  async deleteOrgClassType(ct, organisationId) {
    if (!window.confirm(`Delete class type "${ct.name}"?`)) return;
    try {
      await ajax(`/des/organisations/${organisationId}/class-types/${ct.id}.json`, { type: "DELETE" });
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    }
  }
}
