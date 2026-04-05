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
