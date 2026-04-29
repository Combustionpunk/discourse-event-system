import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { on } from "@ember/modifier";

export default class DesCloneEventModal extends Component {
  @tracked title = this.args.originalTitle || "";
  @tracked startDate = "";

  get minDate() {
    return new Date().toISOString().slice(0, 16);
  }

  @action
  updateTitle(e) {
    this.title = e.target.value;
  }

  @action
  updateStartDate(e) {
    this.startDate = e.target.value;
  }

  @action
  stopPropagation(e) {
    e.stopPropagation();
  }

  @action
  async save() {
    if (!this.title.trim()) {
      alert("Please enter a title for the cloned event");
      return;
    }
    if (!this.startDate) {
      alert("Please select a start date");
      return;
    }
    await this.args.onSave({ title: this.title.trim(), startDate: this.startDate });
  }

  <template>
    <div class="des-modal-overlay" {{on "click" @onClose}}>
      <div class="des-modal" {{on "click" this.stopPropagation}}>
        <div class="des-modal-header">
          <h2>📋 Clone Event</h2>
          <button class="btn btn-flat des-modal-close" {{on "click" @onClose}}>✕</button>
        </div>
        <div class="des-modal-body">
          <div class="org-form-field" style="margin-bottom:16px;">
            <label>New Event Title *</label>
            <input
              type="text"
              value={{this.title}}
              placeholder="Enter event title..."
              {{on "input" this.updateTitle}}
              style="width:100%;"
            />
          </div>
          <div class="org-form-field" style="margin-bottom:24px;">
            <label>New Event Date & Time *</label>
            <input
              type="datetime-local"
              value={{this.startDate}}
              min={{this.minDate}}
              {{on "change" this.updateStartDate}}
              style="width:100%;"
            />
          </div>
          <div class="des-modal-actions">
            <button class="btn btn-primary" {{on "click" this.save}}>📋 Clone Event</button>
            <button class="btn btn-default" {{on "click" @onClose}}>Cancel</button>
          </div>
        </div>
      </div>
    </div>
  </template>
}
