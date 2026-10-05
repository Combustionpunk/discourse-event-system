import { concat, fn, hash } from "@ember/helper";
import { on } from "@ember/modifier";
import { LinkTo } from "@ember/routing";
import { eq } from "discourse/truth-helpers";
import DesClassTypeForm from "../components/des-class-type-form";
import DesLogoUploader from "../components/des-logo-uploader";
import DesVenueForm from "../components/des-venue-form";

const includes = (list, value) => list?.includes(value);

export default <template>
  <div class="des-admin-container">
    <div class="events-nav">
      <LinkTo class="btn btn-default" @route="events">📅 Events</LinkTo>
      <LinkTo class="btn btn-default" @route="organisations">🏢 Organisations</LinkTo>
      <LinkTo class="btn btn-primary" @route="des-admin">⚙️ Admin</LinkTo>
    </div>

    <h1>Event System Admin</h1>

    <div class="des-admin-tabs">
      <button class="btn {{if (eq @controller.activeTab 'organisations') 'btn-primary' 'btn-default'}}" {{on "click" @controller.setTabOrganisations}}>
        🏢 Organisations
        {{#if @controller.model.pending_organisations.length}}
          <span class="pending-badge">{{@controller.model.pending_organisations.length}}</span>
        {{/if}}
      </button>
      <button class="btn {{if (eq @controller.activeTab 'manufacturers') 'btn-primary' 'btn-default'}}" {{on "click" @controller.setTabManufacturers}}>
        🏭 Manufacturers
        {{#if @controller.model.pending_manufacturers.length}}
          <span class="pending-badge">{{@controller.model.pending_manufacturers.length}}</span>
        {{/if}}
      </button>
      <button class="btn {{if (eq @controller.activeTab 'models') 'btn-primary' 'btn-default'}}" {{on "click" @controller.setTabModels}}>
        🚗 Car Models
        {{#if @controller.model.pending_models.length}}
          <span class="pending-badge">{{@controller.model.pending_models.length}}</span>
        {{/if}}
      </button>
      <button class="btn {{if (eq @controller.activeTab 'rules') 'btn-primary' 'btn-default'}}" {{on "click" @controller.setTabRules}}>
        📋 Class Rules
      </button>
      <button class="btn {{if (eq @controller.activeTab 'venues') 'btn-primary' 'btn-default'}}" {{on "click" @controller.setTabVenues}}>
        📍 Venues
      </button>
      <button class="btn {{if (eq @controller.activeTab 'cleanup') 'btn-primary' 'btn-default'}}" {{on "click" @controller.setTabCleanup}}>
        🔧 Cleanup
      </button>
      <button class="btn {{if (eq @controller.activeTab 'scales') 'btn-primary' 'btn-default'}}" {{on "click" @controller.setTabScales}}>
        📏 Scales
      </button>
      <button class="btn {{if (eq @controller.activeTab 'chassis_types') 'btn-primary' 'btn-default'}}" {{on "click" @controller.setTabChassisTypes}}>
        🚗 Chassis Types
      </button>
      <button class="btn {{if (eq @controller.activeTab 'payouts') 'btn-primary' 'btn-default'}}" {{on "click" @controller.setTabPayouts}}>
        💰 Payouts
      </button>
      <button class="btn {{if (eq @controller.activeTab 'suggestions') 'btn-primary' 'btn-default'}}" {{on "click" @controller.setTabSuggestions}}>
        💡 Venue Suggestions
        {{#if @controller.pendingSuggestionsCount}}
          <span class="pending-badge">{{@controller.pendingSuggestionsCount}}</span>
        {{/if}}
      </button>
      <button class="btn {{if (eq @controller.activeTab 'events') 'btn-primary' 'btn-default'}}" {{on "click" (fn @controller.setTab "events")}}>
        📅 Events
      </button>
    </div>

    {{!-- ORGANISATIONS TAB --}}
    {{#if (eq @controller.activeTab "organisations")}}
      <div class="des-admin-section">
        <h2>
          Pending Organisations
          {{#if @controller.model.pending_organisations.length}}
            <span class="pending-badge">{{@controller.model.pending_organisations.length}}</span>
          {{/if}}
        </h2>
        {{#if @controller.model.pending_organisations.length}}
          {{#each @controller.model.pending_organisations as |org|}}
            <div class="admin-org-card admin-org-card--pending">
              <div class="admin-org-info">
                <h3>{{org.name}}</h3>
                <div class="admin-org-meta">
                  <span>👤 {{org.created_by}}</span>
                  {{#if org.contact_email}}<span>✉️ {{org.contact_email}}</span>{{/if}}
                </div>
              </div>
              <div class="admin-org-actions">
                <button class="btn btn-success" {{on "click" (fn @controller.approveOrganisation org)}}>✅ Approve</button>
                <button class="btn btn-danger" {{on "click" (fn @controller.rejectOrganisation org)}}>❌ Reject</button>
              </div>
            </div>
          {{/each}}
        {{else}}
          <p class="no-pending">No pending organisations 🎉</p>
        {{/if}}
      </div>

      <div class="des-admin-section">
        <h2>Approved Organisations ({{@controller.model.approved_organisations.length}})</h2>
        {{#each @controller.model.approved_organisations as |org|}}
          <div class="admin-org-card admin-org-card--approved">
            <div class="admin-org-info">
              <h3>{{org.name}}</h3>
              <div class="admin-org-meta">
                <span>💰 Surcharge: {{org.surcharge_percentage}}%</span>
                {{#if org.contact_email}}<span>✉️ {{org.contact_email}}</span>{{/if}}
              </div>
            </div>
          </div>
        {{/each}}
      </div>

      {{#if @controller.model.rejected_organisations.length}}
        <div class="des-admin-section">
          <h2>Rejected Organisations ({{@controller.model.rejected_organisations.length}})</h2>
          {{#each @controller.model.rejected_organisations as |org|}}
            <div class="admin-org-card admin-org-card--rejected">
              <div class="admin-org-info">
                <h3>{{org.name}}</h3>
                {{#if org.rejection_reason}}
                  <p class="rejection-reason">Reason: {{org.rejection_reason}}</p>
                {{/if}}
              </div>
            </div>
          {{/each}}
        </div>
      {{/if}}
    {{/if}}

    {{!-- MANUFACTURERS TAB --}}
    {{#if (eq @controller.activeTab "manufacturers")}}
      <div class="des-admin-section">
        <div class="section-header">
          <h2>
            Pending Manufacturers
            {{#if @controller.model.pending_manufacturers.length}}
              <span class="pending-badge">{{@controller.model.pending_manufacturers.length}}</span>
            {{/if}}
          </h2>
        </div>
        {{#if @controller.model.pending_manufacturers.length}}
          {{#each @controller.model.pending_manufacturers as |manufacturer|}}
            <div class="admin-org-card admin-org-card--pending">
              <div class="admin-org-info">
                <h3>{{manufacturer.name}}</h3>
                <div class="admin-org-meta">
                  <span>👤 Suggested by: {{manufacturer.created_by}}</span>
                </div>
              </div>
              <div class="admin-org-actions">
                <button class="btn btn-success" {{on "click" (fn @controller.approveManufacturer manufacturer)}}>✅ Approve</button>
                <button class="btn btn-danger" {{on "click" (fn @controller.rejectManufacturer manufacturer)}}>❌ Reject</button>
              </div>
            </div>
          {{/each}}
        {{else}}
          <p class="no-pending">No pending manufacturers 🎉</p>
        {{/if}}
      </div>

      <div class="des-admin-section">
        <div class="section-header">
          <h2>Approved Manufacturers ({{@controller.model.approved_manufacturers.length}})</h2>
          <button class="btn btn-primary btn-small" {{on "click" @controller.toggleAddManufacturerForm}}>
            {{if @controller.showAddManufacturerForm "✕ Cancel" "➕ Add Manufacturer"}}
          </button>
        </div>

        {{#if @controller.showAddManufacturerForm}}
          <div class="add-model-form">
            <h4>Add Manufacturer</h4>
            <div class="org-form-row">
              <div class="org-form-field">
                <label>Manufacturer Name *</label>
                <input placeholder="e.g. Associated RC" type="text" value={{@controller.newManufacturerName}} {{on "input" @controller.updateNewManufacturerName}} />
              </div>
            </div>
            <button class="btn btn-primary" {{on "click" @controller.addManufacturer}}>✅ Add Manufacturer</button>
          </div>
        {{/if}}

        {{#if @controller.model.approved_manufacturers.length}}
          <div class="manufacturers-grid" style="margin-top:16px;">
            {{#each @controller.model.approved_manufacturers as |manufacturer|}}
              <div class="manufacturer-card">
                <div class="manufacturer-card-logo">
                  {{#if manufacturer.logo_url}}
                    <img alt={{manufacturer.name}} class="manufacturer-logo" src={{manufacturer.logo_url}} />
                  {{else}}
                    🏭
                  {{/if}}
                </div>
                <div class="manufacturer-card-name">{{manufacturer.name}}</div>
                <div class="manufacturer-card-actions">
                  <button class="btn btn-default btn-small" {{on "click" (fn @controller.startEditManufacturer manufacturer)}}>✏️ Edit</button>
                  <button class="btn btn-danger btn-small" {{on "click" (fn @controller.deleteManufacturer manufacturer)}}>🗑 Delete</button>
                </div>
              </div>
              {{#if (eq @controller.editingManufacturerId manufacturer.id)}}
                <div class="add-model-form" style="margin-top:8px;">
                  <h4>Edit: {{manufacturer.name}}</h4>
                  <div class="org-form-row">
                    <div class="org-form-field">
                      <label>Name</label>
                      <input type="text" value={{@controller.editingManufacturerName}} {{on "input" @controller.updateEditingManufacturerName}} />
                    </div>
                  </div>
                  <div class="org-form-field" style="margin-top:8px;">
                    <label>Logo</label>
                    <DesLogoUploader
                      @logoUrl={{@controller.editingManufacturerLogoUrl}}
                      @onRemove={{@controller.removeManufacturerLogo}}
                      @onUpload={{@controller.manufacturerLogoUploaded}}
                    />
                  </div>
                  <div style="display:flex;gap:8px;margin-top:12px;">
                    <button class="btn btn-primary" {{on "click" @controller.saveManufacturer}}>💾 Save</button>
                    <button class="btn btn-default" {{on "click" @controller.cancelEditManufacturer}}>✕ Cancel</button>
                  </div>
                </div>
              {{/if}}
            {{/each}}
          </div>
        {{else}}
          <p class="no-pending">No approved manufacturers yet.</p>
        {{/if}}
      </div>
    {{/if}}


    {{!-- CAR MODELS TAB --}}
    {{#if (eq @controller.activeTab "models")}}
      <div class="des-admin-section">
        <h2>
          Pending Car Models
          {{#if @controller.model.pending_models.length}}
            <span class="pending-badge">{{@controller.model.pending_models.length}}</span>
          {{/if}}
        </h2>
        {{#if @controller.model.pending_models.length}}
          {{#each @controller.model.pending_models as |model|}}
            <div class="admin-org-card admin-org-card--pending">
              <div class="admin-org-info">
                <h3>{{model.manufacturer}} {{model.name}}</h3>
                <div class="admin-org-meta">
                  <span>👤 Suggested by: {{model.created_by}}</span>
                  {{#if model.driveline}}<span>⚙️ {{model.driveline}}</span>{{/if}}
                  {{#if model.scale}}<span>📏 {{model.scale}}</span>{{/if}}
                  {{#if model.chassis_type}}<span>🚗 {{model.chassis_type}}</span>{{/if}}
                </div>
              </div>
              <div class="admin-org-actions">
                <button class="btn btn-success btn-small" {{on "click" (fn @controller.startApproveModel model)}}>✅ Approve</button>
                <button class="btn btn-danger btn-small" {{on "click" (fn @controller.rejectModel model)}}>❌ Reject</button>
              </div>
            </div>
            {{#if (eq @controller.approvingModelId model.id)}}
              <div class="add-model-form" style="margin-top: 8px;">
                <h4>Approve: {{model.manufacturer}} {{model.name}}</h4>
                <div class="org-form-row">
                  <div class="org-form-field">
                    <label>Year of First Manufacture</label>
                    <input placeholder="e.g. 2023" type="number" value={{@controller.approveModelForm.year_released}} {{on "input" (fn @controller.updateApproveField "year_released")}} />
                  </div>
                  <div class="org-form-field">
                    <label>Driveline</label>
                    <select {{on "change" (fn @controller.updateApproveField "driveline")}}>
                      <option value="">Select...</option>
                      {{#each @controller.drivelines as |d|}}
                        <option selected={{eq @controller.approveModelForm.driveline d}} value={{d}}>{{d}}</option>
                      {{/each}}
                    </select>
                  </div>
                  <div class="org-form-field">
                    <label>Scale</label>
                    <select {{on "change" (fn @controller.updateApproveField "scale")}}>
                      <option value="">Select...</option>
                      {{#each @controller.scales as |s|}}
                        <option selected={{eq @controller.approveModelForm.scale s}} value={{s}}>{{s}}</option>
                      {{/each}}
                    </select>
                  </div>
                  <div class="org-form-field">
                    <label>Chassis Type</label>
                    <select {{on "change" (fn @controller.updateApproveField "chassis_type")}}>
                      <option value="">Select...</option>
                      {{#each @controller.chassisTypes as |c|}}
                        <option selected={{eq @controller.approveModelForm.chassis_type c}} value={{c}}>{{c}}</option>
                      {{/each}}
                    </select>
                  </div>
                </div>
                <div style="display:flex;gap:8px;margin-top:8px;">
                  <button class="btn btn-primary" {{on "click" @controller.confirmApproveModel}}>✅ Confirm Approval</button>
                  <button class="btn btn-default" {{on "click" @controller.cancelApproveModel}}>✕ Cancel</button>
                </div>
              </div>
            {{/if}}
          {{/each}}
        {{else}}
          <p class="no-pending">No pending car models 🎉</p>
        {{/if}}
      </div>

      <div class="des-admin-section">
        <div class="section-header">
          <h2>Approved Car Models ({{@controller.model.approved_models.length}})</h2>
          <button class="btn btn-primary btn-small" {{on "click" @controller.toggleAddModelForm}}>
            {{if @controller.showAddModelForm "✕ Cancel" "+ Add Model"}}
          </button>
        </div>

        {{#if @controller.showAddModelForm}}
          <div class="add-model-form">
            <div class="org-form-row">
              <div class="org-form-field">
                <label>Manufacturer *</label>
                <select {{on "change" (fn @controller.updateNewModel "manufacturer_id")}}>
                  <option value="">Select manufacturer...</option>
                  {{#each @controller.model.approved_manufacturers as |mfr|}}
                    <option value={{mfr.id}}>{{mfr.name}}</option>
                  {{/each}}
                </select>
              </div>
              <div class="org-form-field">
                <label>Model Name *</label>
                <input placeholder="e.g. B7.1" type="text" {{on "input" (fn @controller.updateNewModel "name")}} />
              </div>
            </div>
            <div class="org-form-row">
              <div class="org-form-field">
                <label>Year Released</label>
                <input max="2030" min="1970" placeholder="e.g. 2024" type="number" {{on "input" (fn @controller.updateNewModel "year_released")}} />
              </div>
              <div class="org-form-field">
                <label>Driveline</label>
                <select {{on "change" (fn @controller.updateNewModel "driveline")}}>
                  <option value="">Select...</option>
                  {{#each @controller.drivelines as |d|}}
                    <option value={{d}}>{{d}}</option>
                  {{/each}}
                </select>
              </div>
              <div class="org-form-field">
                <label>Scale</label>
                <select {{on "change" (fn @controller.updateNewModel "scale")}}>
                  <option value="">Select...</option>
                  {{#each @controller.scales as |s|}}
                    <option value={{s}}>{{s}}</option>
                  {{/each}}
                </select>
              </div>
              <div class="org-form-field">
                <label>Chassis Type</label>
                <select {{on "change" (fn @controller.updateNewModel "chassis_type")}}>
                  <option value="">Select...</option>
                  {{#each @controller.chassisTypes as |c|}}
                    <option value={{c}}>{{c}}</option>
                  {{/each}}
                </select>
              </div>
            </div>
            <button class="btn btn-primary" {{on "click" @controller.createModel}}>
              ✅ Add Model
            </button>
          </div>
        {{/if}}

        <p class="field-help">Edit year, driveline or chassis type for any approved model.</p>
        {{#each @controller.model.approved_models_by_manufacturer as |mfr|}}
          <div class="models-manufacturer-group">
            <h3 class="models-manufacturer-heading">🏭 {{mfr.manufacturer}}</h3>
            <div class="models-grid">
              {{#each mfr.models as |model|}}
                <div class="model-card">
                  <div class="model-card-header">
                    <strong>{{model.name}}</strong>
                    {{#if model.scale}}<span class="driveline-badge">📏 {{model.scale}}</span>{{/if}}
                    {{#if model.chassis_type}}
                      <span class="driveline-badge">🚗 {{model.chassis_type}}</span>
                    {{else}}
                      <span class="pending-tag">⚠️ No chassis</span>
                    {{/if}}
                  </div>
                  <div class="model-card-meta">
                    {{#if model.year_released}}<span>📅 {{model.year_released}}</span>{{/if}}
                    {{#if model.driveline}}<span class="driveline-badge">{{model.driveline}}</span>{{/if}}
                  </div>
                  <div class="model-card-actions">
                    <LinkTo class="btn btn-default btn-small" @model={{model.id}} @query={{hash edit="1"}} @route="car-model">
                      ✏️ Edit
                    </LinkTo>
                    <button class="btn btn-danger btn-small" {{on "click" (fn @controller.deleteModel model)}}>
                      🗑 Delete
                    </button>
                  </div>
                </div>
              {{/each}}
            </div>
          </div>
        {{/each}}
      </div>
    {{/if}}

    {{!-- CLASS RULES TAB --}}
    {{#if (eq @controller.activeTab "rules")}}
      <div class="des-admin-section">
        <h2>Class Compatibility Rules</h2>
        <p class="field-help">Define global class types with eligibility rules. All fields are optional — leave blank to allow any value.</p>

        <div class="section-header">
          <button class="btn btn-primary btn-small" {{on "click" @controller.toggleAddClassTypeForm}}>
            {{if @controller.showAddClassTypeForm "✕ Cancel" "+ Add Class Type"}}
          </button>
        </div>

        {{#if @controller.showAddClassTypeForm}}
          <div class="add-model-form">
            <h3>New Class Type</h3>
            <DesClassTypeForm
              @manufacturers={{@controller.model.approved_manufacturers}}
              @models={{@controller.model.approved_models}}
              @onCancel={{@controller.toggleAddClassTypeForm}}
              @onSave={{@controller.createClassType}}
              @saveLabel="✅ Create Class Type"
            />
          </div>
        {{/if}}

        <h3 style="margin-top: 16px;">Global Class Types</h3>
        {{#each @controller.model.global_class_types as |ct|}}
          <div class="admin-org-card">
            <div class="admin-org-info">
              <strong>{{ct.name}}</strong>
              <div class="admin-org-meta">
                {{#if ct.track_environment}}<span>{{if (eq ct.track_environment "onroad") "🛣️ On-Road" "🌿 Off-Road"}}</span>{{/if}}
                {{#if ct.scale}}<span>📏 {{ct.scale}}</span>{{/if}}
                {{#if ct.chassis_types.length}}<span>🚗 {{ct.chassis_types}}</span>{{/if}}
                {{#if ct.drivelines.length}}<span>⚙️ {{ct.drivelines}}</span>{{/if}}
                {{#if ct.min_year}}<span>📅 From {{ct.min_year}}</span>{{/if}}
                {{#if ct.max_year}}<span>📅 Until {{ct.max_year}}</span>{{/if}}
                {{#if ct.manufacturer}}<span>🏭 {{ct.manufacturer}}</span>{{/if}}
                {{#if ct.min_age}}<span>👤 Age {{ct.min_age}}+</span>{{/if}}
                {{#if ct.max_age}}<span>👤 Age ≤{{ct.max_age}}</span>{{/if}}
              </div>
            </div>
            <div class="admin-org-actions">
              <button class="btn btn-default btn-small" {{on "click" (fn @controller.startEditClassType ct)}}>✏️ Edit</button>
              <button class="btn btn-danger btn-small" {{on "click" (fn @controller.deleteClassType ct)}}>🗑 Delete</button>
            </div>
          </div>
          {{#if (eq @controller.editingClassTypeId ct.id)}}
            <DesClassTypeForm
              @classType={{ct}}
              @manufacturers={{@controller.model.approved_manufacturers}}
              @models={{@controller.model.approved_models}}
              @onCancel={{@controller.cancelEditClassType}}
              @onSave={{@controller.saveEditClassType}}
              @saveLabel="💾 Save Changes"
            />
          {{/if}}
        {{/each}}

        {{#if @controller.model.org_class_type_groups.length}}
          <h3 style="margin-top: 32px;">Organisation Class Types</h3>
          <p class="field-help">Class types created by each organisation for their own events.</p>
          {{#each @controller.model.org_class_type_groups as |group|}}
            <div class="admin-org-card" style="margin-bottom: 8px;">
              <div class="admin-org-info" role="button" style="cursor: pointer;" {{on "click" (fn @controller.toggleOrgClassGroup group.organisation_id)}}>
                <strong>{{group.organisation_name}}</strong>
                <span class="field-help" style="margin-left: 8px;">{{group.class_types.length}} class type(s)</span>
                <span style="float: right;">{{if (includes @controller.expandedOrgGroups group.organisation_id) "▼" "▶"}}</span>
              </div>
            </div>
            {{#if (includes @controller.expandedOrgGroups group.organisation_id)}}
              {{#each group.class_types as |ct|}}
                <div class="admin-org-card" style="margin-left: 24px; margin-bottom: 8px;">
                  <div class="admin-org-info">
                    <strong>{{ct.name}}</strong>
                    <div class="admin-org-meta">
                      {{#if ct.track_environment}}<span>{{if (eq ct.track_environment "onroad") "🛣️ On-Road" "🌿 Off-Road"}}</span>{{/if}}
                      {{#if ct.scale}}<span>📏 {{ct.scale}}</span>{{/if}}
                      {{#if ct.chassis_types.length}}<span>🚗 {{ct.chassis_types}}</span>{{/if}}
                      {{#if ct.drivelines.length}}<span>⚙️ {{ct.drivelines}}</span>{{/if}}
                      {{#if ct.min_year}}<span>📅 From {{ct.min_year}}</span>{{/if}}
                      {{#if ct.max_year}}<span>📅 Until {{ct.max_year}}</span>{{/if}}
                      {{#if ct.manufacturer}}<span>🏭 {{ct.manufacturer}}</span>{{/if}}
                      {{#if ct.min_age}}<span>👤 Age {{ct.min_age}}+</span>{{/if}}
                      {{#if ct.max_age}}<span>👤 Age ≤{{ct.max_age}}</span>{{/if}}
                    </div>
                  </div>
                  <div class="admin-org-actions">
                    <button class="btn btn-default btn-small" {{on "click" (fn @controller.startEditClassType ct)}}>✏️ Edit</button>
                    <button class="btn btn-danger btn-small" {{on "click" (fn @controller.deleteOrgClassType ct group.organisation_id)}}>🗑 Delete</button>
                  </div>
                </div>
                {{#if (eq @controller.editingClassTypeId ct.id)}}
                  <DesClassTypeForm
                    @classType={{ct}}
                    @manufacturers={{@controller.model.approved_manufacturers}}
                    @models={{@controller.model.approved_models}}
                    @onCancel={{@controller.cancelEditClassType}}
                    @onSave={{@controller.saveEditClassType}}
                    @saveLabel="💾 Save Changes"
                  />
                {{/if}}
              {{/each}}
            {{/if}}
          {{/each}}
        {{/if}}
      </div>
    {{/if}}




    {{!-- CLEANUP TAB --}}
    {{#if (eq @controller.activeTab "cleanup")}}
      <div class="des-admin-section">
        <h2>🔧 Orphaned Cars</h2>
        <p class="field-help">Cars with missing or rejected manufacturers/models.</p>

        {{#if @controller.orphanedCars.length}}
          {{#each @controller.orphanedCars as |car|}}
            <div class="admin-org-card">
              {{#if (eq @controller.editingOrphanCarId car.id)}}
                <div class="orphan-edit-form" style="width:100%;">
                  <strong>{{car.friendly_name}}</strong> <span class="field-help">({{car.username}})</span>
                  <div class="org-form-row" style="margin-top:8px;">
                    <div class="org-form-field">
                      <label>Manufacturer</label>
                      <select {{on "change" @controller.updateOrphanMfr}}>
                        <option value="">Select...</option>
                        {{#each @controller.model.approved_manufacturers as |mfr|}}
                          <option selected={{eq (concat mfr.id "") (concat @controller.editingOrphanMfr "")}} value={{mfr.id}}>{{mfr.name}}</option>
                        {{/each}}
                      </select>
                    </div>
                    <div class="org-form-field">
                      <label>Model</label>
                      <select {{on "change" @controller.updateOrphanModel}}>
                        <option value="">Select...</option>
                        {{#each @controller.orphanModels as |m|}}
                          <option selected={{eq (concat m.id "") (concat @controller.editingOrphanModel "")}} value={{m.id}}>{{m.name}}</option>
                        {{/each}}
                      </select>
                    </div>
                  </div>
                  <div style="display:flex;gap:6px;margin-top:8px;">
                    <button class="btn btn-primary btn-small" {{on "click" (fn @controller.saveOrphanCar car)}}>Save</button>
                    <button class="btn btn-default btn-small" {{on "click" @controller.cancelEditOrphanCar}}>Cancel</button>
                  </div>
                </div>
              {{else}}
                <div class="admin-org-info">
                  <strong>{{car.friendly_name}}</strong>
                  <div class="admin-org-meta">
                    <span>👤 {{car.username}}</span>
                    <span>🏭 {{if car.manufacturer_name car.manufacturer_name "⚠️ No manufacturer"}}</span>
                    <span>🚗 {{if car.model_name car.model_name "⚠️ No model"}}
                      {{#if car.model_status}}
                        <span class="booking-status booking-status--{{car.model_status}}">{{car.model_status}}</span>
                      {{/if}}
                    </span>
                  </div>
                </div>
                <div class="admin-org-actions">
                  <button class="btn btn-default btn-small" {{on "click" (fn @controller.startEditOrphanCar car)}}>✏️ Fix</button>
                  <button class="btn btn-danger btn-small" {{on "click" (fn @controller.deleteOrphanCar car)}}>🗑 Delete</button>
                </div>
              {{/if}}
            </div>
          {{/each}}
        {{else}}
          <p class="no-pending">No orphaned cars found 🎉</p>
        {{/if}}
      </div>
    {{/if}}


    {{!-- VENUES TAB --}}
    {{#if (eq @controller.activeTab "venues")}}
      <div class="des-admin-section">
        <div class="section-header" style="margin-bottom:16px;display:flex;gap:8px;align-items:center;">
          <button class="btn btn-default btn-small" disabled={{@controller.isGeocoding}} {{on "click" @controller.geocodeAllVenues}}>
            {{if @controller.isGeocoding "⏳ Geocoding..." "📍 Fetch Missing Coordinates"}}
          </button>
          {{#if @controller.geocodeResult}}
            <span class="field-help">{{@controller.geocodeResult}}</span>
          {{/if}}
          <button class="btn btn-primary btn-small" {{on "click" @controller.toggleAddVenueForm}}>
            {{if @controller.showAddVenueForm "✕ Cancel" "+ Add Venue"}}
          </button>
        </div>

        {{#if @controller.showAddVenueForm}}
          <div class="add-model-form">
            <h3>New Venue</h3>
            <DesVenueForm
              @onCancel={{@controller.toggleAddVenueForm}}
              @onSave={{@controller.createAdminVenue}}
              @saveLabel="✅ Create Venue"
            />
          </div>
        {{/if}}

        <h2>Pending Venues</h2>
        {{#if @controller.adminVenues.length}}
          {{#each @controller.adminVenues as |venue|}}
            {{#if (eq venue.status "pending")}}
              <div class="admin-org-card admin-org-card--pending">
                <div class="admin-org-info">
                  <h3>{{venue.name}}</h3>
                  <div class="admin-org-meta">
                    <span>📍 {{venue.address}}</span>
                    {{#if venue.organisation_name}}<span>🏢 {{venue.organisation_name}}</span>{{/if}}
                    <span class="booking-status booking-status--pending">pending</span>
                  </div>
                </div>
                <div class="admin-org-actions">
                  <button class="btn btn-success" {{on "click" (fn @controller.approveVenue venue)}}>✅ Approve</button>
                  <button class="btn btn-danger" {{on "click" (fn @controller.deleteVenue venue)}}>❌ Delete</button>
                </div>
              </div>
            {{/if}}
          {{/each}}
        {{/if}}

        <h2>Approved Venues</h2>
        {{#each @controller.adminVenues as |venue|}}
          {{#if (eq venue.status "approved")}}
            <div class="admin-org-card">
              <div class="admin-org-info">
                <strong>{{venue.name}}</strong>
                <div class="admin-org-meta">
                  {{#if venue.address}}<span>📍 {{venue.address}}</span>{{/if}}
                  {{#each venue.tracks as |track|}}
                    {{#if track.surface}}<span>{{track.surface}}</span>{{/if}}
                    {{#if track.environment}}<span>{{track.environment}}</span>{{/if}}
                  {{/each}}
                  {{#if venue.is_shared}}<span>🤝 Shared</span>{{/if}}
                  {{#if venue.has_permanent_toilets}}<span>🚻</span>{{/if}}
                  {{#if venue.has_portaloos}}<span>🚽</span>{{/if}}
                  {{#if venue.has_cafe}}<span>☕</span>{{/if}}
                  {{#if venue.has_bar}}<span>🍺</span>{{/if}}
                  {{#if venue.has_showers}}<span>🚿</span>{{/if}}
                  {{#if venue.has_power_supply}}<span>⚡</span>{{/if}}
                  {{#if venue.has_water_supply}}<span>💧</span>{{/if}}
                  {{#if venue.has_camping}}<span>⛺</span>{{/if}}
                </div>
              </div>
              <div class="admin-org-actions">
                {{#if (eq venue.claim_status "pending")}}
                  <span class="pending-badge">Claim: {{venue.claimed_organisation_name}}</span>
                  <button class="btn btn-success btn-small" {{on "click" (fn @controller.approveVenueClaim venue)}}>✅ Approve Claim</button>
                  <button class="btn btn-danger btn-small" {{on "click" (fn @controller.rejectVenueClaim venue)}}>❌ Reject</button>
                {{/if}}
                {{#if (eq venue.claim_status "approved")}}
                  <span class="field-help">🏠 {{venue.claimed_organisation_name}}</span>
                {{/if}}
                <button class="btn btn-small btn-default" {{on "click" (fn @controller.startEditVenue venue)}}>✏️ Edit</button>
                <button class="btn btn-small btn-danger" {{on "click" (fn @controller.deleteVenue venue)}}>🗑 Delete</button>
              </div>
            </div>
            {{#if (eq @controller.editingVenueId venue.id)}}
              <DesVenueForm
                @onCancel={{@controller.cancelEditVenue}}
                @onSave={{@controller.saveEditVenue}}
                @saveLabel="💾 Save Changes"
                @venue={{venue}}
              />
            {{/if}}
          {{/if}}
        {{/each}}

        <div class="des-admin-section" style="margin-top:24px;">
          <h3>🔀 Merge Duplicate Venues</h3>
          <p class="field-help">Select two venues to merge. The second venue will be deleted and all its events re-linked to the first.</p>
          <div style="display:flex;gap:12px;align-items:flex-end;flex-wrap:wrap;">
            <div class="org-form-field">
              <label>Keep this venue</label>
              <select {{on "change" @controller.updateMergeKeep}}>
                <option value="">Select venue to keep...</option>
                {{#each @controller.adminVenues as |venue|}}
                  <option value={{venue.id}}>{{venue.name}} (ID: {{venue.id}})</option>
                {{/each}}
              </select>
            </div>
            <div class="org-form-field">
              <label>Delete and merge this venue</label>
              <select {{on "change" @controller.updateMergeDuplicate}}>
                <option value="">Select venue to delete...</option>
                {{#each @controller.adminVenues as |venue|}}
                  <option value={{venue.id}}>{{venue.name}} (ID: {{venue.id}})</option>
                {{/each}}
              </select>
            </div>
            <button class="btn btn-danger" disabled={{@controller.cannotMerge}} {{on "click" @controller.mergeVenues}}>
              🔀 Merge Venues
            </button>
          </div>
        </div>
      </div>
    {{/if}}

    {{!-- SCALES TAB --}}
    {{#if (eq @controller.activeTab "scales")}}
      <div class="des-admin-section">
        <h2>📏 Scales</h2>
        <div class="admin-list">
          {{#each @controller.scalesList as |scale|}}
            <div class="admin-list-item">
              <span>{{scale.name}}</span>
              <button class="btn btn-danger btn-small" {{on "click" (fn @controller.deleteScale scale)}}>🗑️ Delete</button>
            </div>
          {{/each}}
        </div>
        <div class="admin-add-form">
          <input placeholder="New scale (e.g. 1/5)" type="text" value={{@controller.newScaleName}} {{on "input" (fn @controller.updateAdminField "newScaleName")}} />
          <button class="btn btn-primary" {{on "click" @controller.addScale}}>➕ Add Scale</button>
        </div>
      </div>
    {{/if}}

    {{!-- CHASSIS TYPES TAB --}}
    {{#if (eq @controller.activeTab "chassis_types")}}
      <div class="des-admin-section">
        <h2>🚗 Chassis Types</h2>
        <div class="admin-list">
          {{#each @controller.chassisTypesList as |ct|}}
            <div class="admin-list-item">
              <span>{{ct.name}}</span>
              <button class="btn btn-danger btn-small" {{on "click" (fn @controller.deleteChassisType ct)}}>🗑️ Delete</button>
            </div>
          {{/each}}
        </div>
        <div class="admin-add-form">
          <input placeholder="New chassis type (e.g. Crawler)" type="text" value={{@controller.newChassisTypeName}} {{on "input" (fn @controller.updateAdminField "newChassisTypeName")}} />
          <button class="btn btn-primary" {{on "click" @controller.addChassisType}}>➕ Add Chassis Type</button>
        </div>
      </div>
    {{/if}}

    {{!-- PAYOUTS TAB --}}
    {{#if (eq @controller.activeTab "payouts")}}
      <div class="des-admin-section">
        <div style="display:flex;gap:8px;margin-bottom:20px;align-items:center;flex-wrap:wrap;">
          <span style="font-weight:600;">Period:</span>
          <button class="btn btn-small {{if (eq @controller.payoutPeriod 'all') 'btn-primary' 'btn-default'}}" {{on "click" (fn @controller.setPayoutPeriod "all")}}>All Time</button>
          <button class="btn btn-small {{if (eq @controller.payoutPeriod 'year') 'btn-primary' 'btn-default'}}" {{on "click" (fn @controller.setPayoutPeriod "year")}}>This Year</button>
          <button class="btn btn-small {{if (eq @controller.payoutPeriod 'month') 'btn-primary' 'btn-default'}}" {{on "click" (fn @controller.setPayoutPeriod "month")}}>This Month</button>
          <button class="btn btn-small {{if (eq @controller.payoutPeriod '7days') 'btn-primary' 'btn-default'}}" {{on "click" (fn @controller.setPayoutPeriod "7days")}}>Last 7 Days</button>
        </div>

        {{#if @controller.adminPayoutSummary}}
          <div class="payout-summary-cards" style="margin-bottom:24px;">
            <div class="payout-summary-card">
              <div class="payout-summary-label">Total Gross</div>
              <div class="payout-summary-value">£{{@controller.adminPayoutSummary.total_gross}}</div>
            </div>
            <div class="payout-summary-card" style="border-color:var(--success);">
              <div class="payout-summary-label">RC Misfits Earned</div>
              <div class="payout-summary-value" style="color:var(--success);">£{{@controller.adminPayoutSummary.total_surcharge}}</div>
            </div>
            <div class="payout-summary-card">
              <div class="payout-summary-label">Total Paid Out</div>
              <div class="payout-summary-value">£{{@controller.adminPayoutSummary.total_paid}}</div>
            </div>
            <div class="payout-summary-card" style="border-color:var(--highlight);">
              <div class="payout-summary-label">Unclaimed</div>
              <div class="payout-summary-value" style="color:var(--highlight-high);">£{{@controller.adminPayoutSummary.total_unclaimed}}</div>
            </div>
          </div>
        {{/if}}

        {{#if @controller.adminPayoutsLoading}}
          <p>Loading payouts...</p>
        {{else if @controller.adminPayouts.length}}
          <table class="payout-history-table">
            <thead>
              <tr>
                <th>Event</th>
                <th>Organisation</th>
                <th>Date</th>
                <th>Gross</th>
                <th>Surcharge</th>
                <th>Net</th>
                <th>Status</th>
                <th>Action</th>
              </tr>
            </thead>
            <tbody>
              {{#each @controller.adminPayouts as |payout|}}
                <tr>
                  <td>{{payout.event_title}}</td>
                  <td>{{payout.organisation_name}}</td>
                  <td>{{payout.event_date}}</td>
                  <td>£{{payout.gross_amount}}</td>
                  <td>£{{payout.surcharge_amount}}</td>
                  <td>£{{payout.net_amount}}</td>
                  <td><span class="payout-status-badge payout-status--{{payout.status}}">{{payout.status}}</span></td>
                  <td>
                    {{#if (eq payout.status "pending")}}
                      <button class="btn btn-primary btn-small" disabled={{@controller.approvingPayoutId}} {{on "click" (fn @controller.adminApprovePayout payout)}}>
                        {{if (eq @controller.approvingPayoutId payout.event_id) "..." "✅ Approve"}}
                      </button>
                    {{else}}
                      <span style="color:var(--primary-medium);font-size:0.85em;">{{payout.status}}</span>
                    {{/if}}
                  </td>
                </tr>
              {{/each}}
            </tbody>
          </table>
        {{else}}
          <p class="field-help">No payouts found for this period.</p>
        {{/if}}
      </div>
    {{/if}}

    {{!-- EVENTS TAB --}}
    {{#if (eq @controller.activeTab "events")}}
      <div class="des-admin-section">
        <h2>Events ({{@controller.model.events.length}})</h2>
        {{#if @controller.model.events.length}}
          {{#each @controller.model.events as |event|}}
            <div class="admin-org-card">
              <div class="admin-org-info">
                <strong>{{event.title}}</strong>
                <div class="admin-org-meta">
                  <span>🏢 {{event.organisation_name}}</span>
                  <span>📅 {{event.start_date}}</span>
                  <span class="booking-status booking-status--{{event.status}}">{{event.status}}</span>
                </div>
              </div>
              <div class="admin-org-actions">
                <a class="btn btn-default btn-small" href="/events/{{event.id}}/manage">⚙️ Manage</a>
                <button class="btn btn-danger btn-small" {{on "click" (fn @controller.deleteEvent event)}}>🗑 Delete</button>
              </div>
            </div>
          {{/each}}
        {{else}}
          <p class="no-pending">No events found.</p>
        {{/if}}
      </div>
    {{/if}}

    {{!-- VENUE SUGGESTIONS TAB --}}
    {{#if (eq @controller.activeTab "suggestions")}}
      <div class="des-admin-section">
        <h2>💡 Pending Venue Suggestions</h2>
        {{#if @controller.suggestionsLoading}}
          <p class="field-help">Loading...</p>
        {{else if @controller.pendingSuggestions.length}}
          {{#each @controller.pendingSuggestions as |suggestion|}}
            <div class="admin-org-card" style="margin-bottom:12px;">
              <div class="admin-org-header">
                <strong>{{suggestion.venue_name}}</strong>
                <span class="field-help">by {{suggestion.user}} — {{suggestion.created_at}}</span>
              </div>
              <div style="padding:8px 12px;">
                <h4>Suggested changes:</h4>
                <pre style="background:var(--primary-very-low);padding:8px;border-radius:4px;font-size:0.85em;white-space:pre-wrap;max-height:200px;overflow:auto;">{{@controller.formatSuggestion suggestion.suggested_data}}</pre>
                <div style="display:flex;gap:8px;margin-top:8px;">
                  <button class="btn btn-success btn-small" {{on "click" (fn @controller.approveSuggestion suggestion)}}>✅ Approve & Apply</button>
                  <button class="btn btn-danger btn-small" {{on "click" (fn @controller.rejectSuggestion suggestion)}}>❌ Reject</button>
                  <a class="btn btn-default btn-small" href="/venues/{{suggestion.venue_id}}" rel="noopener noreferrer" target="_blank">View Venue</a>
                </div>
              </div>
            </div>
          {{/each}}
        {{else}}
          <p class="field-help">No pending suggestions.</p>
        {{/if}}

        {{#if @controller.resolvedSuggestions.length}}
          <h3 style="margin-top:24px;">Recent Resolved</h3>
          {{#each @controller.resolvedSuggestions as |suggestion|}}
            <div class="admin-org-card" style="margin-bottom:8px;opacity:0.7;">
              <div class="admin-org-header">
                <strong>{{suggestion.venue_name}}</strong>
                <span class="field-help">{{suggestion.status}} — by {{suggestion.user}} — {{suggestion.created_at}}</span>
                {{#if suggestion.admin_notes}}<span class="field-help">Note: {{suggestion.admin_notes}}</span>{{/if}}
              </div>
            </div>
          {{/each}}
        {{/if}}
      </div>
    {{/if}}

  </div>
</template>
