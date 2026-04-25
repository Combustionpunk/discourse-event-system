import Controller from "@ember/controller";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { tracked } from "@glimmer/tracking";
import { inject as service } from "@ember/service";

export default class EventManageController extends Controller {
  @service router;
  @service currentUser;
  @tracked isSaving = false;
  @tracked activeTab = "details";
  @tracked editMode = false;
  @tracked editDescription = "";
  @tracked editRcResultsMeetingId = null;
  @tracked classTypes = null;
  @tracked newClassTypeId = null;
  @tracked newClassCapacity = "";
  @tracked editingClassId = null;
  @tracked editingClassCapacity = "";
  @tracked entrantsFilter = "all";
  @tracked results = { status: 'none' };
  @tracked isLoadingResults = false;
  @tracked isImporting = false;
  @tracked isPublishing = false;
  @tracked isSavingMatches = false;
  @tracked pendingMatches = {};

  get isChampionshipRound() {
    return this.model.event.event_type?.name?.toLowerCase().includes('championship');
  }
  @tracked swapCarEntrant = null;
  @tracked swapCarClassId = null;
  @tracked swapCarOptions = [];
  @tracked moveClassEntrant = null;
  @tracked moveClassFromId = null;

  get filteredEntrantsClasses() {
    const classes = this.model.entrants?.classes || [];
    if (this.entrantsFilter === "all") return classes;
    return classes.map(cls => ({
      ...cls,
      entrants: cls.entrants.filter(e => e.status === this.entrantsFilter)
    }));
  }

  get entrantsStatusCounts() {
    const classes = this.model.entrants?.classes || [];
    const counts = { all: 0, confirmed: 0, pending: 0, cancelled: 0, waitlist: 0 };
    classes.forEach(cls => {
      (cls.entrants || []).forEach(e => {
        counts.all++;
        if (counts[e.status] !== undefined) {
          counts[e.status]++;
        }
      });
    });
    return counts;
  }

  @action
  setEntrantsFilter(filter) {
    this.entrantsFilter = filter;
  }

  @action
  setTab(tab) {
    this.activeTab = tab;
    if (tab === "results") {
      this.loadResults();
    }
  }




  @action
  async downloadCsv() {
    try {
      const csrfToken = document.querySelector("meta[name='csrf-token']")?.content;
      const response = await fetch("/des/events/" + this.model.event.id + "/export-csv", {
        credentials: "same-origin",
        headers: {
          "X-CSRF-Token": csrfToken,
          "X-Requested-With": "XMLHttpRequest"
        }
      });
      if (!response.ok) throw new Error("Failed");
      const text = await response.text();
      const blob = new Blob([text], { type: "text/csv" });
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = this.model.event.title.replace(/[^a-z0-9]/gi, "-").toLowerCase() + "-entries.csv";
      document.body.appendChild(a);
      a.click();
      window.URL.revokeObjectURL(url);
      document.body.removeChild(a);
    } catch (error) {
      alert("Failed to download CSV");
    }
  }

  @action
  showDetails() {
    this.activeTab = "details";
  }

  @action
  showEntrants() {
    this.activeTab = "entrants";
  }

  @action
  showPricing() {
    this.activeTab = "pricing";
    const p = this.model.event.pricing || {};
    this.pricingForm = {
      rule_type: p.rule_type || "tiered",
      first_class_price: p.first_class_price || "",
      subsequent_class_price: p.subsequent_class_price || "",
      member_first_class_discount: p.member_first_class_discount || "",
      member_subsequent_discount: p.member_subsequent_discount || "",
      junior_first_class_discount: p.junior_first_class_discount || "",
      junior_subsequent_discount: p.junior_subsequent_discount || "",
    };
  }

  @action
  updatePricingForm(field, e) {
    this.pricingForm = { ...this.pricingForm, [field]: e.target.value };
  }

  @action
  async savePricing() {
    try {
      await ajax("/des/events/" + this.model.event.id + "/pricing.json", {
        type: "PUT",
        data: { pricing: this.pricingForm },
      });
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  async showClasses() {
    this.activeTab = "classes";
    if (!this.classTypes) {
      try {
        const result = await ajax("/des/class-types.json");
        this.classTypes = result.class_types;
        if (this.classTypes.length) {
          this.newClassTypeId = this.classTypes[0].id;
        }
      } catch (error) {
        popupAjaxError(error);
      }
    }
  }

  @action
  updateNewClassTypeId(e) {
    this.newClassTypeId = parseInt(e.target.value, 10);
  }

  @action
  updateNewClassCapacity(e) {
    this.newClassCapacity = e.target.value;
  }

  @action
  async addClass() {
    if (!this.newClassTypeId || !this.newClassCapacity) return;
    try {
      await ajax("/des/events/" + this.model.event.id + "/classes.json", {
        type: "POST",
        data: {
          class_type_id: this.newClassTypeId,
          capacity: this.newClassCapacity,
        },
      });
      this.newClassCapacity = "";
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  startEditClass(cls) {
    this.editingClassId = cls.id;
    this.editingClassCapacity = cls.capacity;
  }

  @action
  cancelEditClass() {
    this.editingClassId = null;
    this.editingClassCapacity = "";
  }

  @action
  updateEditingCapacity(e) {
    this.editingClassCapacity = e.target.value;
  }

  @action
  async saveClassCapacity(cls) {
    try {
      await ajax("/des/events/" + this.model.event.id + "/classes/" + cls.id + ".json", {
        type: "PUT",
        data: { capacity: this.editingClassCapacity },
      });
      this.editingClassId = null;
      this.editingClassCapacity = "";
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  async toggleClassStatus(cls) {
    const action = cls.status === "inactive" ? "reopen" : "close";
    if (!window.confirm(`Are you sure you want to ${action} ${cls.name}?`)) return;
    try {
      await ajax("/des/events/" + this.model.event.id + "/classes/" + cls.id + "/toggle-status.json", {
        type: "POST",
      });
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  async deleteClass(cls) {
    if (!window.confirm(`Delete ${cls.name}? This cannot be undone.`)) return;
    try {
      await ajax("/des/events/" + this.model.event.id + "/classes/" + cls.id + ".json", {
        type: "DELETE",
      });
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    }
  }


  @action
  async cancelEntrant(entrant, className) {
    if (!window.confirm(`Cancel ${entrant.username}'s booking for ${className}?`)) return;
    try {
      await ajax("/des/events/" + this.model.event.id + "/cancel-entrant.json", {
        type: "POST",
        data: {
          booking_id: entrant.booking_id,
          booking_class_id: entrant.booking_class_id,
        },
      });
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  async deleteBooking(entrant, className) {
    if (!window.confirm(`Permanently delete ${entrant.username}'s booking for ${className}? This cannot be undone.`)) return;
    try {
      await ajax("/des/events/" + this.model.event.id + "/bookings/" + entrant.booking_id + ".json", {
        type: "DELETE",
      });
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  async removeFromWaitlist(entrant) {
    if (!window.confirm("Remove " + entrant.username + " from the waitlist?")) return;
    try {
      await ajax("/des/events/" + this.model.event.id + "/waitlist/" + entrant.waitlist_id + ".json", {
        type: "DELETE",
      });
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    }
  }


  @action
  async startSwapCar(entrant, classId) {
    this.swapCarEntrant = entrant;
    this.swapCarClassId = classId;
    try {
      const response = await ajax("/des/bookings/eligible-cars.json", {
        data: { event_id: this.model.event.id, class_ids: [classId], user_id: entrant.user_id }
      });
      this.swapCarOptions = response.classes?.[0]?.eligible_cars || [];
    } catch { this.swapCarOptions = []; }
  }

  @action cancelSwapCar() {
    this.swapCarEntrant = null;
    this.swapCarClassId = null;
    this.swapCarOptions = [];
  }

  @action
  async confirmSwapCar(carId) {
    if (!this.swapCarEntrant) return;
    try {
      await ajax("/des/events/" + this.model.event.id + "/bookings/" + this.swapCarEntrant.booking_id + "/classes/" + this.swapCarEntrant.booking_class_id + "/car.json", {
        type: "PUT",
        data: { car_id: carId }
      });
      this.swapCarEntrant = null;
      this.swapCarOptions = [];
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  startMoveClass(entrant, fromClassId) {
    this.moveClassEntrant = entrant;
    this.moveClassFromId = fromClassId;
  }

  @action cancelMoveClass() {
    this.moveClassEntrant = null;
    this.moveClassFromId = null;
  }

  @action
  async confirmMoveClass(toClassId) {
    if (!this.moveClassEntrant) return;
    try {
      await ajax("/des/events/" + this.model.event.id + "/bookings/" + this.moveClassEntrant.booking_id + "/move-class.json", {
        type: "PUT",
        data: {
          from_class_id: this.moveClassFromId,
          to_class_id: toClassId
        }
      });
      this.moveClassEntrant = null;
      this.moveClassFromId = null;
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  get moveClassOptions() {
    if (!this.model.entrants?.classes) return [];
    return this.model.entrants.classes
      .filter(c => c.id !== this.moveClassFromId && c.spaces_remaining > 0)
      .map(c => ({ id: c.id, name: c.name, spaces: c.spaces_remaining }));
  }

  @action
  async syncTransponders() {
    if (!window.confirm("Sync transponder numbers from current car records for all bookings in this event?")) return;
    try {
      const response = await ajax("/des/events/" + this.model.event.id + "/sync-transponders.json", { type: "POST" });
      alert(response.message);
      if (response.updated > 0) this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    }
  }




  @action
  toggleEdit() {
    this.editMode = !this.editMode;
    if (this.editMode) this.editDescription = this.model.event.description || "";
    if (this.editMode) this.editRcResultsMeetingId = this.model.event.rc_results_meeting_id || null;
  }

  @action
  updateField(field, event) {
    if (field === "editRcResultsMeetingId") {
      this.editRcResultsMeetingId = event.target.value;
    } else {
      this.model.event[field] = event.target.value;
    }
  }

  @action
  async saveChanges() {
    this.isSaving = true;
    try {
      await ajax("/des/events/" + this.model.event.id + ".json", {
        type: "PUT",
        data: {
          event: {
            title: this.model.event.title,
            description: this.editDescription,
            start_date: this.model.event.start_date ? new Date(this.model.event.start_date).toISOString() : null,
            end_date: this.model.event.end_date ? new Date(this.model.event.end_date).toISOString() : null,
            booking_closing_date: this.model.event.booking_closing_date ? new Date(this.model.event.booking_closing_date).toISOString() : null,
            location: this.model.event.location,
            google_maps_url: this.model.event.google_maps_url,
            max_classes_per_booking: this.model.event.max_classes_per_booking,
            venue_id: this.model.event.venue_id,
            rc_results_meeting_id: this.editRcResultsMeetingId,
          }
        },
      });
      this.editMode = false;
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.isSaving = false;
    }
  }

  @action
  async publishEvent() {
    if (!window.confirm("Publish this event? It will become visible to all users.")) return;
    try {
      await ajax("/des/events/" + this.model.event.id + "/publish.json", {
        type: "POST",
      });
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  async cancelEvent() {
    const reason = window.prompt("Please provide a reason for cancelling this event:");
    if (!reason) return;
    if (!window.confirm("Are you sure? This will cancel all bookings and issue refunds.")) return;
    try {
      await ajax("/des/events/" + this.model.event.id + "/cancel.json", {
        type: "POST",
        data: { reason },
      });
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  async loadResults() {
    this.isLoadingResults = true;
    try {
      const response = await ajax(`/des/events/${this.model.event.id}/results.json`);
      this.results = response;
    } catch {
      this.results = { status: 'none' };
    } finally {
      this.isLoadingResults = false;
    }
  }

  @action
  async importResults() {
    if (!window.confirm("Import results from RC Results? This will overwrite any existing results.")) return;
    this.isImporting = true;
    try {
      const response = await ajax(`/des/events/${this.model.event.id}/results/import.json`, {
        type: "POST"
      });
      this.results = response;
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.isImporting = false;
    }
  }

  @action
  updateMatch(entryId, event) {
    this.pendingMatches = { ...this.pendingMatches, [entryId]: event.target.value };
  }

  getMatchValue(entryId) {
    return this.pendingMatches[entryId] || '';
  }

  @action
  async saveMatches() {
    this.isSavingMatches = true;
    try {
      const matches = {};
      for (const [entryId, username] of Object.entries(this.pendingMatches)) {
        if (username.trim()) {
          try {
            const userResponse = await ajax(`/u/${username.trim()}.json`);
            matches[entryId] = userResponse.user?.id;
          } catch {
            // Username not found, skip
          }
        } else {
          matches[entryId] = null;
        }
      }
      const response = await ajax(`/des/events/${this.model.event.id}/results/matches.json`, {
        type: "PUT",
        data: { matches }
      });
      this.results = response;
      this.pendingMatches = {};
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.isSavingMatches = false;
    }
  }

  @action
  async publishResults() {
    if (!window.confirm("Publish results and award badges? This cannot be undone.")) return;
    this.isPublishing = true;
    try {
      const response = await ajax(`/des/events/${this.model.event.id}/results/publish.json`, {
        type: "POST"
      });
      this.results = response;
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.isPublishing = false;
    }
  }

}
