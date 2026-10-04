import { tracked } from "@glimmer/tracking";
import Controller from "@ember/controller";
import { action } from "@ember/object";
import { schedule } from "@ember/runloop";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import discourseDebounce from "discourse/lib/debounce";
import { i18n } from "discourse-i18n";

const CURRENT_ERA_START_YEAR = 2015;
const SEARCH_DEBOUNCE_MS = 250;
const LIST_FILTER_KEYS = ["type", "drive", "era"];

function compareNames(a, b) {
  return (a || "").localeCompare(b || "", undefined, { sensitivity: "base" });
}

function parseList(value) {
  return value ? value.split(",").filter(Boolean) : [];
}

export default class CarModelsController extends Controller {
  @service currentUser;
  @service dialog;
  @service router;

  @tracked q = "";
  @tracked type = "";
  @tracked drive = "";
  @tracked era = "";
  @tracked searchInput = null;
  @tracked showSuggestManufacturer = false;

  @tracked showAddManufacturer = false;
  @tracked newManufacturerName = "";
  @tracked approvingModelId = null;
  @tracked
  approveModelForm = { year_released: "", driveline: "", scale: "", chassis_type: "", power_type: "" };
  @tracked editingModelId = null;
  @tracked
  editModelForm = { name: "", year_released: "", driveline: "", scale: "", chassis_type: "", power_type: "" };
  @tracked addingModelForManufacturerId = null;
  @tracked
  newModelForm = { name: "", year_released: "", driveline: "", scale: "", chassis_type: "", power_type: "" };
  @tracked scales = [];
  @tracked chassisTypes = [];
  @tracked editingManufacturerId = null;

  @tracked editManufacturerName = "";

  @tracked editManufacturerLogoUploadId = null;

  @tracked editManufacturerLogoUrl = null;

  @tracked showSuggestModelModal = false;

  @tracked suggestModelPreselectedManufacturer = null;

  @tracked showAddCarModal = false;

  @tracked addCarManufacturerId = null;

  @tracked addCarModelId = null;

  queryParams = ["q", "type", "drive", "era"];

  constructor() {
    super(...arguments);
    this.loadScalesAndChassisTypes();
  }

  get approvedManufacturers() {
    return (this.model.manufacturers || []).filter(m => m.status === "approved");
  }

  get searchValue() {
    return this.searchInput ?? this.q;
  }

  get isAdmin() {
    return !!this.currentUser?.admin;
  }

  get allModels() {
    return (this.model.models_by_manufacturer || []).flatMap(
      (group) => group.models
    );
  }

  get approvedModels() {
    return this.allModels.filter((m) => m.status === "approved");
  }

  // Admins review pending models in the panel; suggesters see their own inline.
  get sectionModels() {
    const username = this.currentUser?.username;
    return this.allModels.filter(
      (m) =>
        m.status === "approved" ||
        (!this.isAdmin &&
          username &&
          m.status === "pending" &&
          m.created_by === username)
    );
  }

  get pendingModels() {
    if (!this.isAdmin) {
      return [];
    }
    const filters = this.activeFilters;
    return this.allModels
      .filter((m) => m.status === "pending" && this.#matches(m, filters))
      .sort(
        (a, b) =>
          compareNames(a.manufacturer_name, b.manufacturer_name) ||
          compareNames(a.name, b.name)
      );
  }

  get activeFilters() {
    return {
      search: this.q.trim().toLowerCase(),
      type: parseList(this.type),
      drive: parseList(this.drive),
      era: parseList(this.era),
    };
  }

  get hasActiveFilters() {
    const { search, type, drive, era } = this.activeFilters;
    return !!search || type.length > 0 || drive.length > 0 || era.length > 0;
  }

  get filteredModels() {
    const filters = this.activeFilters;
    return this.sectionModels.filter((m) => this.#matches(m, filters));
  }

  get filterGroups() {
    const { type, drive, era } = this.activeFilters;
    const distinct = (field) =>
      [...new Set(this.approvedModels.map((m) => m[field]).filter(Boolean))]
        .sort(compareNames)
        .map((value) => ({ value, label: value }));
    const withState = (options, active) =>
      options.map((o) => ({ ...o, active: active.includes(o.value) }));

    return [
      {
        key: "type",
        label: i18n("discourse_event_system.car_models.filters.type"),
        options: withState(distinct("chassis_type"), type),
      },
      {
        key: "drive",
        label: i18n("discourse_event_system.car_models.filters.drive"),
        options: withState(distinct("driveline"), drive),
      },
      {
        key: "era",
        label: i18n("discourse_event_system.car_models.filters.era"),
        options: withState(
          [
            {
              value: "current",
              label: i18n("discourse_event_system.car_models.filters.era_current"),
            },
            {
              value: "vintage",
              label: i18n("discourse_event_system.car_models.filters.era_vintage"),
            },
          ],
          era
        ),
      },
    ];
  }

  get manufacturerTiles() {
    const filtered = this.filteredModels;
    return [...this.approvedManufacturers]
      .sort((a, b) => compareNames(a.name, b.name))
      .map((manufacturer) => {
        const totalCount = this.approvedModels.filter(
          (m) => m.manufacturer_id === manufacturer.id
        ).length;
        const matchCount = filtered.filter(
          (m) => m.manufacturer_id === manufacturer.id && m.status === "approved"
        ).length;
        return {
          manufacturer,
          totalCount,
          matchCount,
          isEmpty: matchCount === 0,
          isDisabled:
            matchCount === 0 && (totalCount > 0 || !this.currentUser),
          title: this.#tileTitle(manufacturer, totalCount, matchCount),
        };
      });
  }

  get manufacturerSections() {
    const filtered = this.filteredModels;
    return [...(this.model.manufacturers || [])]
      .filter((mfr) => mfr.status !== "rejected")
      .sort((a, b) => compareNames(a.name, b.name))
      .map((manufacturer) => {
        const models = filtered
          .filter((m) => m.manufacturer_id === manufacturer.id)
          .sort((a, b) => compareNames(a.name, b.name));
        return {
          manufacturer,
          models,
          count: models.filter((m) => m.status === "approved").length,
        };
      })
      .filter(
        (section) =>
          section.models.length > 0 ||
          section.manufacturer.id === this.addingModelForManufacturerId
      );
  }

  get pendingManufacturers() {
    return (this.model.manufacturers || []).filter(m => m.status === "pending");
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
    if (!this.newManufacturerName.trim()) {return;}
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
    if (!this.newManufacturerName.trim()) {return;}
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
    if (!window.confirm(`Reject manufacturer "${mfr.name}"?`)) {return;}
    try {
      await ajax(`/des/admin/manufacturers/${mfr.id}.json`, { type: "DELETE" });
      this.router.refresh();
    } catch (error) { popupAjaxError(error); }
  }

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
    if (!this.editManufacturerName.trim()) {return;}
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
    this.newModelForm = { name: "", year_released: "", driveline: "", scale: "", chassis_type: "", power_type: "" };
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
    if (!this.newModelForm.name.trim()) {return;}
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
      chassis_type: model.chassis_type || "",
      power_type: model.power_type || ""
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
    const confirmed = await this.dialog.yesNoConfirm({
      message: i18n("discourse_event_system.car_models.confirm_reject", {
        name: model.name,
      }),
    });
    if (!confirmed) {
      return;
    }
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
      chassis_type: model.chassis_type || "",
      power_type: model.power_type || "",
      box_art_upload_id: model.box_art_upload_id || null,
      box_art_url: model.box_art_url || null,
    };
  }

  @action
  editBoxArtUploaded(upload) {
    this.editModelForm = {
      ...this.editModelForm,
      box_art_upload_id: upload.id,
      box_art_url: upload.url,
    };
  }

  @action
  removeEditBoxArt() {
    this.editModelForm = {
      ...this.editModelForm,
      box_art_upload_id: null,
      box_art_url: null,
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
      const form = this.editModelForm;
      await ajax(`/des/admin/models/${this.editingModelId}.json`, {
        type: "PUT",
        data: {
          name: form.name,
          year_released: form.year_released,
          driveline: form.driveline,
          scale: form.scale,
          chassis_type: form.chassis_type,
          power_type: form.power_type,
          // Blank clears the box art server-side.
          box_art_upload_id: form.box_art_upload_id || "",
        },
      });
      this.editingModelId = null;
      this.router.refresh();
    } catch (error) { popupAjaxError(error); }
  }

  @action
  async deleteModel(model) {
    const confirmed = await this.dialog.deleteConfirm({
      message: i18n("discourse_event_system.car_models.confirm_delete", {
        name: model.name,
      }),
    });
    if (!confirmed) {
      return;
    }
    try {
      await ajax(`/des/admin/models/${model.id}.json`, { type: "DELETE" });
      this.router.refresh();
    } catch (error) { popupAjaxError(error); }
  }

  @action
  openSuggestModelModal(manufacturer = null) {
    this.suggestModelPreselectedManufacturer = manufacturer;
    this.showSuggestModelModal = true;
  }

  @action
  closeSuggestModelModal() {
    this.showSuggestModelModal = false;
    this.suggestModelPreselectedManufacturer = null;
  }

  @action
  onModelSuggested() {
    this.showSuggestModelModal = false;
    this.suggestModelPreselectedManufacturer = null;
    this.router.refresh();
  }

  @action
  addToGarage(model) {
    this.addCarManufacturerId = model.manufacturer_id;
    this.addCarModelId = model.id;
    this.showAddCarModal = true;
  }

  @action
  closeAddCarModal() {
    this.showAddCarModal = false;
    this.addCarManufacturerId = null;
    this.addCarModelId = null;
  }

  @action
  onCarAdded() {
    this.showAddCarModal = false;
    this.addCarManufacturerId = null;
    this.addCarModelId = null;
  }

  @action
  onSearchInput(event) {
    this.searchInput = event.target.value;
    discourseDebounce(this, this.#applySearch, SEARCH_DEBOUNCE_MS);
  }

  @action
  clearSearch() {
    this.searchInput = null;
    this.q = "";
  }

  @action
  toggleFilter(key, value) {
    if (!LIST_FILTER_KEYS.includes(key)) {
      return;
    }
    const values = parseList(this[key]);
    this[key] = (
      values.includes(value)
        ? values.filter((v) => v !== value)
        : [...values, value]
    ).join(",");
  }

  @action
  clearFilters() {
    this.clearSearch();
    LIST_FILTER_KEYS.forEach((key) => (this[key] = ""));
  }

  @action
  selectManufacturerTile(tile) {
    const { manufacturer } = tile;

    if (tile.matchCount > 0) {
      this.#scrollToManufacturer(manufacturer.id);
    } else if (tile.totalCount === 0 && this.isAdmin) {
      this.startAddModel(manufacturer.id);
      schedule("afterRender", () =>
        this.#scrollToManufacturer(manufacturer.id)
      );
    } else if (tile.totalCount === 0 && this.currentUser) {
      this.openSuggestModelModal(manufacturer);
    }
  }

  // Hand the input back to the query param so back/forward navigation stays in sync.
  #applySearch() {
    if (this.searchInput !== null) {
      this.q = this.searchInput;
      this.searchInput = null;
    }
  }

  #matches(model, { search, type, drive, era }) {
    if (search) {
      const haystack =
        `${model.name} ${model.manufacturer_name || ""}`.toLowerCase();
      if (!haystack.includes(search)) {
        return false;
      }
    }

    if (type.length && !type.includes(model.chassis_type)) {
      return false;
    }

    if (drive.length && !drive.includes(model.driveline)) {
      return false;
    }

    if (era.length) {
      const year = parseInt(model.year_released, 10);
      if (!year) {
        return false;
      }
      const modelEra = year >= CURRENT_ERA_START_YEAR ? "current" : "vintage";
      if (!era.includes(modelEra)) {
        return false;
      }
    }

    return true;
  }

  #tileTitle(manufacturer, totalCount, matchCount) {
    if (matchCount > 0) {
      return manufacturer.name;
    }
    if (totalCount > 0) {
      return i18n("discourse_event_system.car_models.tile_no_matches");
    }
    if (this.isAdmin) {
      return i18n("discourse_event_system.car_models.tile_add", {
        manufacturer: manufacturer.name,
      });
    }
    if (this.currentUser) {
      return i18n("discourse_event_system.car_models.tile_suggest", {
        manufacturer: manufacturer.name,
      });
    }
    return i18n("discourse_event_system.car_models.tile_no_models");
  }

  #scrollToManufacturer(id) {
    document
      .getElementById(`manufacturer-${id}`)
      ?.scrollIntoView({ behavior: "smooth", block: "start" });
  }
}
