import Controller from "@ember/controller";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { tracked } from "@glimmer/tracking";
import { inject as service } from "@ember/service";

export default class EventManageController extends Controller {
  @service router;
  @tracked isSaving = false;
  @tracked activeTab = "details";
  @tracked editMode = false;
  @tracked classTypes = null;
  @tracked newClassTypeId = null;
  @tracked newClassCapacity = "";
  @tracked editingClassId = null;
  @tracked editingClassCapacity = "";

  @action
  setTab(tab) {
    this.activeTab = tab;
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
  toggleEdit() {
    this.editMode = !this.editMode;
  }

  @action
  updateField(field, event) {
    this.model.event[field] = event.target.value;
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
            description: this.model.event.description,
            start_date: this.model.event.start_date,
            end_date: this.model.event.end_date,
            booking_closing_date: this.model.event.booking_closing_date,
            location: this.model.event.location,
            google_maps_url: this.model.event.google_maps_url,
            max_classes_per_booking: this.model.event.max_classes_per_booking,
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
}
