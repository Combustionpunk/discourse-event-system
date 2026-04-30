import Controller from "@ember/controller";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { tracked } from "@glimmer/tracking";
import { inject as service } from "@ember/service";

export default class VenuesController extends Controller {
  @service router;
  @tracked showForm = false;
  @tracked showAdminAddVenue = false;
  @tracked isSaving = false;
  @tracked newVenue = {};
  @tracked viewMode = "list";
  @tracked showIconKey = false;

  trackCategories = ["onroad", "offroad"];
  trackSurfaces = ["carpet", "astroturf", "grass", "tarmac", "mixed"];
  trackEnvironments = ["outdoor", "indoor_covered"];

  get canSuggest() {
    return this.model.myOrgs && this.model.myOrgs.length > 0;
  }

  @action toggleForm() {
    this.showForm = !this.showForm;
    if (this.showForm) {
      this.newVenue = {
        name: "", address: "", google_maps_url: "", track_category: "",
        track_surface: "", track_environment: "", website: "", description: "",
        parking_info: "", local_facilities: "", access_notes: "",
        created_by_organisation_id: this.model.myOrgs[0]?.id || "",
        has_portaloos: false, has_permanent_toilets: false, has_bar: false,
        has_showers: false, has_power_supply: false, has_water_supply: false, has_camping: false,
      };
    }
  }

  @action updateField(field, e) {
    this.newVenue = { ...this.newVenue, [field]: e.target.value };
  }

  @action
  toggleAdminAddVenue() {
    this.showAdminAddVenue = !this.showAdminAddVenue;
  }

  @action
  async adminSaveVenue(formData) {
    try {
      await ajax("/des/venues.json", {
        type: "POST",
        data: formData
      });
      this.showAdminAddVenue = false;
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  async saveVenue(formData) {
    this.isSaving = true;
    try {
      await ajax("/des/venues.json", {
        type: "POST",
        data: { ...formData, created_by_organisation_id: this.newVenue?.created_by_organisation_id }
      });
      this.showForm = false;
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.isSaving = false;
    }
  }

  @action
  toggleIconKey() {
    this.showIconKey = !this.showIconKey;
  }

  @action
  stopPropagation(e) {
    e.stopPropagation();
  }

  @action
  setViewMode(mode) {
    this.viewMode = mode;
    if (mode === "map") {
      setTimeout(() => this.initMap(), 100);
    }
  }

  initMap() {
    if (window.L) {
      this.renderMap();
      return;
    }

    const link = document.createElement('link');
    link.rel = 'stylesheet';
    link.href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css';
    document.head.appendChild(link);

    const script = document.createElement('script');
    script.src = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js';
    script.onload = () => this.renderMap();
    document.head.appendChild(script);
  }

  renderMap() {
    const mapEl = document.getElementById('venues-map');
    if (!mapEl) return;

    if (this._map) {
      this._map.remove();
      this._map = null;
    }

    const venues = (this.model.venues || []).filter(v => v.latitude && v.longitude);

    if (!venues.length) {
      mapEl.innerHTML = '<div style="display:flex;align-items:center;justify-content:center;height:100%;color:var(--primary-medium);">No venues with location data. Add postcodes to venues and click "Fetch Missing Coordinates" in DES Admin.</div>';
      return;
    }

    const avgLat = venues.reduce((sum, v) => sum + parseFloat(v.latitude), 0) / venues.length;
    const avgLng = venues.reduce((sum, v) => sum + parseFloat(v.longitude), 0) / venues.length;

    const map = window.L.map('venues-map').setView([avgLat, avgLng], 7);
    this._map = map;

    window.L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
      maxZoom: 18
    }).addTo(map);

    const surfaceMap = { carpet: '🟫 Carpet', astroturf: '🌿 Astroturf', grass: '🍃 Grass', tarmac: '⬛ Tarmac', mixed: '🔀 Mixed' };

    venues.forEach(venue => {
      const facilityIcons = [
        venue.has_permanent_toilets ? '🚻' : '',
        venue.has_portaloos ? '🚽' : '',
        venue.has_cafe ? '☕' : '',
        venue.has_bar ? '🍺' : '',
        venue.has_showers ? '🚿' : '',
        venue.has_power_supply ? '⚡' : '',
        venue.has_water_supply ? '💧' : '',
        venue.has_camping ? '⛺' : '',
      ].filter(Boolean).join(' ');

      const envIcon = venue.track_environment === 'outdoor' ? '🌳' : venue.track_environment ? '🏠' : '';
      const surface = venue.track_surface ? surfaceMap[venue.track_surface] || venue.track_surface : '';

      const popup = `
        <div style="min-width:180px;">
          <strong style="font-size:1.1em;">${venue.name}</strong>
          ${venue.address ? `<p style="margin:4px 0;font-size:0.85em;color:#666;">${venue.address}</p>` : ''}
          ${envIcon || surface ? `<p style="margin:4px 0;">${envIcon} ${surface}</p>` : ''}
          ${facilityIcons ? `<p style="margin:4px 0;">${facilityIcons}</p>` : ''}
          <a href="/venues/${venue.id}" style="display:inline-block;margin-top:8px;padding:4px 10px;background:#0088cc;color:white;border-radius:4px;text-decoration:none;font-size:0.85em;">View Venue</a>
        </div>
      `;

      window.L.marker([parseFloat(venue.latitude), parseFloat(venue.longitude)])
        .addTo(map)
        .bindPopup(popup);
    });

    if (venues.length > 1) {
      const bounds = window.L.latLngBounds(venues.map(v => [parseFloat(v.latitude), parseFloat(v.longitude)]));
      map.fitBounds(bounds, { padding: [40, 40] });
    }
  }
}
