import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { concat } from "@ember/helper";
import { on } from "@ember/modifier";
import { fn } from "@ember/helper";
import { eq, gt } from "truth-helpers";

export default class DesCloneEventModal extends Component {
  @tracked clones = [
    { title: this.args.originalTitle || "", startDate: "" }
  ];
  @tracked isSaving = false;

  get minDate() {
    return new Date().toISOString().slice(0, 16);
  }

  @action
  addClone() {
    this.clones = [
      ...this.clones,
      { title: this.args.originalTitle || "", startDate: "" }
    ];
  }

  @action
  removeClone(index) {
    this.clones = this.clones.filter((_, i) => i !== index);
  }

  @action
  updateCloneTitle(index, e) {
    const updated = [...this.clones];
    updated[index] = { ...updated[index], title: e.target.value };
    this.clones = updated;
  }

  @action
  updateCloneDate(index, e) {
    const updated = [...this.clones];
    updated[index] = { ...updated[index], startDate: e.target.value };
    this.clones = updated;
  }

  @action
  stopPropagation(e) {
    e.stopPropagation();
  }

  @action
  async save() {
    const invalid = this.clones.find(c => !c.title.trim() || !c.startDate);
    if (invalid) {
      alert("Please fill in all titles and dates before saving.");
      return;
    }
    this.isSaving = true;
    try {
      await this.args.onSave(this.clones);
    } finally {
      this.isSaving = false;
    }
  }

  <template>
    <div class="des-modal-overlay" {{on "click" @onClose}}>
      <div class="des-modal" style="max-width:720px;" {{on "click" this.stopPropagation}}>
        <div class="des-modal-header">
          <h2>📋 Clone Event</h2>
          <button class="btn btn-flat des-modal-close" {{on "click" @onClose}}>✕</button>
        </div>
        <div class="des-modal-body">
          <p class="field-help" style="margin-bottom:16px;">Add one or more dates to clone this event to. Each clone will be created as a draft.</p>

          {{#each this.clones as |clone index|}}
            <div class="clone-row" style="display:flex;gap:12px;align-items:flex-start;margin-bottom:12px;padding:12px;background:var(--primary-very-low);border-radius:6px;">
              <div class="org-form-field" style="flex:2;">
                <label>Title</label>
                <input
                  type="text"
                  value={{clone.title}}
                  placeholder="Event title..."
                  {{on "input" (fn this.updateCloneTitle index)}}
                  style="width:100%;"
                />
              </div>
              <div class="org-form-field" style="flex:1.5;">
                <label>Date & Time</label>
                <input
                  type="datetime-local"
                  value={{clone.startDate}}
                  min={{this.minDate}}
                  {{on "change" (fn this.updateCloneDate index)}}
                  style="width:100%;"
                />
              </div>
              {{#if (gt this.clones.length 1)}}
                <div style="padding-top:22px;">
                  <button class="btn btn-danger btn-small" {{on "click" (fn this.removeClone index)}}>✕</button>
                </div>
              {{/if}}
            </div>
          {{/each}}

          <button class="btn btn-default btn-small" style="margin-bottom:24px;" {{on "click" this.addClone}}>
            ➕ Add another date
          </button>

          <div class="des-modal-actions">
            <button class="btn btn-primary" disabled={{this.isSaving}} {{on "click" this.save}}>
              {{if this.isSaving "Creating..." (if (gt this.clones.length 1) (concat "📋 Clone " this.clones.length " Events") "📋 Clone Event")}}
            </button>
            <button class="btn btn-default" {{on "click" @onClose}}>Cancel</button>
          </div>
        </div>
      </div>
    </div>
  </template>
}
