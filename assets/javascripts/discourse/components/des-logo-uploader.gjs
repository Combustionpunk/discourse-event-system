import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { on } from "@ember/modifier";

export default class DesLogoUploader extends Component {
  @tracked isUploading = false;

  @action
  async handleFileChange(event) {
    const file = event.target.files[0];
    if (!file) return;

    this.isUploading = true;

    try {
      const formData = new FormData();
      formData.append("files[]", file);
      formData.append("type", "composer");

      const response = await fetch("/uploads.json", {
        method: "POST",
        headers: {
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")?.content
        },
        body: formData
      });

      const data = await response.json();

      if (data.id && data.url) {
        this.args.onUpload({ id: data.id, url: data.url });
      }
    } catch (error) {
      // eslint-disable-next-line no-console
      console.error("Upload failed:", error);
    } finally {
      this.isUploading = false;
    }
  }

  <template>
    <div class="des-logo-uploader">
      {{#if @logoUrl}}
        <div class="logo-preview" style="margin-bottom:8px;">
          <img src={{@logoUrl}} alt="Logo" style="height:60px;width:auto;object-fit:contain;" />
          <button class="btn btn-small btn-danger" style="margin-left:8px;" {{on "click" @onRemove}}>🗑 Remove</button>
        </div>
      {{/if}}

      <label class="btn btn-default btn-small" style="cursor:pointer;display:inline-block;">
        {{#if this.isUploading}}
          ⏳ Uploading...
        {{else}}
          📁 {{if @logoUrl "Change Logo" "Upload Logo"}}
        {{/if}}
        <input
          type="file"
          accept="image/*"
          style="display:none;"
          {{on "change" this.handleFileChange}}
          disabled={{this.isUploading}}
        />
      </label>
      <p class="field-help" style="margin-top:4px;">PNG, JPG or SVG recommended. Will display at 60px height.</p>
    </div>
  </template>
}
