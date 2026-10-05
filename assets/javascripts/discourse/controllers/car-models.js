import { tracked } from "@glimmer/tracking";
import Controller from "@ember/controller";
import { action } from "@ember/object";
import { schedule } from "@ember/runloop";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import discourseDebounce from "discourse/lib/debounce";
import { i18n } from "discourse-i18n";
import { carModelSlug } from "../components/des-car-model-card";
import DesMergeCarModelModal from "../components/des-merge-car-model-modal";
import DesNameTidyModal from "../components/des-name-tidy-modal";

const CURRENT_ERA_START_YEAR = 2015;
const SEARCH_DEBOUNCE_MS = 250;
const LIST_FILTER_KEYS = ["type", "drive", "era", "show"];

function compareNames(a, b) {
  return (a || "").localeCompare(b || "", undefined, { sensitivity: "base" });
}

const SORT_MODES = ["name", "popular", "newest"];

const MODEL_COMPARATORS = {
  name: (a, b) => compareNames(a.name, b.name),
  popular: (a, b) =>
    (b.racer_count || 0) - (a.racer_count || 0) || compareNames(a.name, b.name),
  newest: (a, b) =>
    (b.year_released ?? -Infinity) - (a.year_released ?? -Infinity) ||
    compareNames(a.name, b.name),
};

function parseList(value) {
  return value ? value.split(",").filter(Boolean) : [];
}

export default class CarModelsController extends Controller {
  @service currentUser;
  @service dialog;
  @service modal;
  @service router;
  @service toasts;

  @tracked q = "";
  @tracked type = "";
  @tracked drive = "";
  @tracked era = "";
  @tracked show = "";
  @tracked sort = "name";
  @tracked locallyPendingBoxArtIds = [];
  @tracked locallyAddedGarageIds = [];
  @tracked searchInput = null;
  @tracked showSuggestManufacturer = false;

  @tracked showAddManufacturer = false;
  @tracked newManufacturerName = "";
  @tracked approvingModelId = null;
  @tracked
  approveModelForm = { year_released: "", driveline: "", scale: "", chassis_type: "", power_type: "" };
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

  queryParams = ["q", "type", "drive", "era", "show", "sort"];

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

  get canEdit() {
    return !!this.model.can_edit;
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
        (!this.canEdit &&
          username &&
          m.status === "pending" &&
          m.created_by === username)
    );
  }

  get pendingModels() {
    if (!this.canEdit) {
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

  get pendingBoxArtModelIds() {
    return new Set([
      ...(this.model.my_pending_box_art_model_ids || []),
      ...this.locallyPendingBoxArtIds,
    ]);
  }

  get garageModelIds() {
    return new Set([
      ...(this.model.my_garage_model_ids || []),
      ...this.locallyAddedGarageIds,
    ]);
  }

  get imageSuggestions() {
    const filters = this.activeFilters;
    const modelsById = new Map(this.allModels.map((m) => [m.id, m]));
    return (this.model.image_suggestions || []).filter((suggestion) => {
      const carModel = modelsById.get(suggestion.car_model_id);
      return carModel && this.#matches(carModel, filters);
    });
  }

  get activeFilters() {
    return {
      search: this.q.trim().toLowerCase(),
      type: parseList(this.type),
      drive: parseList(this.drive),
      era: parseList(this.era),
      show: parseList(this.show),
    };
  }

  get hasActiveFilters() {
    const { search, ...lists } = this.activeFilters;
    return !!search || Object.values(lists).some((list) => list.length > 0);
  }

  get filteredModels() {
    const filters = this.activeFilters;
    return this.sectionModels.filter((m) => this.#matches(m, filters));
  }

  get filterGroups() {
    const { type, drive, era, show } = this.activeFilters;
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
      {
        key: "show",
        label: i18n("discourse_event_system.car_models.filters.show"),
        options: withState(this.#showOptions(), show),
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

  get sortMode() {
    return SORT_MODES.includes(this.sort) ? this.sort : "name";
  }

  get isFlatView() {
    return this.sortMode === "popular";
  }

  get sortOptions() {
    return SORT_MODES.map((value) => ({
      value,
      label: i18n(`discourse_event_system.car_models.sort.${value}`),
      active: value === this.sortMode,
    }));
  }

  get flatModels() {
    const logos = new Map(
      (this.model.manufacturers || []).map((m) => [m.id, m.logo_url])
    );
    return [...this.filteredModels]
      .sort(MODEL_COMPARATORS.popular)
      .map((model) => ({ model, logoUrl: logos.get(model.manufacturer_id) }));
  }

  get manufacturerSections() {
    const filtered = this.filteredModels;
    return [...(this.model.manufacturers || [])]
      .filter((mfr) => mfr.status !== "rejected")
      .sort((a, b) => compareNames(a.name, b.name))
      .map((manufacturer) => {
        const models = filtered
          .filter((m) => m.manufacturer_id === manufacturer.id)
          .sort(MODEL_COMPARATORS[this.sortMode]);
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
    const confirmed = await this.dialog.yesNoConfirm({
      message: i18n("discourse_event_system.car_models.confirm_reject_manufacturer", {
        name: mfr.name,
      }),
    });
    if (!confirmed) {
      return;
    }
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
  openMerge(source) {
    this.modal.show(DesMergeCarModelModal, {
      model: {
        source,
        models: this.allModels,
        onMerged: () => this.router.refresh(),
      },
    });
  }

  @action
  openNameTidy() {
    this.modal.show(DesNameTidyModal, {
      model: { onApplied: () => this.router.refresh() },
    });
  }

  @action
  async suggestBoxArt(model, upload) {
    try {
      const result = await ajax(`/des/car-models/${model.id}/box-art.json`, {
        type: "POST",
        data: { upload_id: upload.id },
      });
      if (result.applied) {
        this.toasts.success({
          duration: "short",
          data: {
            message: i18n("discourse_event_system.car_models.box_art.applied"),
          },
        });
        this.router.refresh();
      } else {
        this.locallyPendingBoxArtIds = [
          ...this.locallyPendingBoxArtIds,
          model.id,
        ];
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
  async approveImageSuggestion(suggestion) {
    try {
      await ajax(`/des/admin/image-suggestions/${suggestion.id}/approve.json`, {
        type: "POST",
      });
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  async rejectImageSuggestion(suggestion) {
    try {
      await ajax(`/des/admin/image-suggestions/${suggestion.id}/reject.json`, {
        type: "POST",
      });
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    }
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
  editModel(model) {
    this.router.transitionTo("car-model", carModelSlug(model), {
      queryParams: { edit: "1" },
    });
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
  onCarAdded(car) {
    const modelId = car?.model?.id ?? this.addCarModelId;
    if (modelId) {
      this.locallyAddedGarageIds = [...this.locallyAddedGarageIds, modelId];
    }
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
  setSort(value) {
    this.sort = value;
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
    } else if (tile.totalCount === 0 && this.canEdit) {
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

  #matches(model, { search, type, drive, era, show }) {
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

    if (show.includes("missing_box_art") && model.box_art_url) {
      return false;
    }

    if (show.includes("mine") && !this.garageModelIds.has(model.id)) {
      return false;
    }

    return true;
  }

  #showOptions() {
    const options = [];
    if (this.currentUser) {
      options.push({
        value: "mine",
        label: i18n("discourse_event_system.car_models.filters.my_cars"),
      });
    }
    if (this.canEdit) {
      options.push({
        value: "missing_box_art",
        label: i18n("discourse_event_system.car_models.filters.missing_box_art"),
      });
    }
    return options;
  }

  #tileTitle(manufacturer, totalCount, matchCount) {
    if (matchCount > 0) {
      return manufacturer.name;
    }
    if (totalCount > 0) {
      return i18n("discourse_event_system.car_models.tile_no_matches");
    }
    if (this.canEdit) {
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
