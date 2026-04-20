import Controller from "@ember/controller";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { tracked } from "@glimmer/tracking";
import { inject as service } from "@ember/service";

export default class EventNewController extends Controller {
  @service router;
  @tracked isSaving = false;
  @tracked classes = [];
  @tracked bookingType = "internal";
  @tracked pricingType = "tiered";
  @tracked description = "";

  get pricingIsFlat() {
    return this.pricingType === "flat";
  }

  get isExternalBooking() {
    return this.bookingType === "external";
  }


  get globalClassTypes() {
    return (this.model.class_types || []).filter(ct => !ct.isOrg);
  }

  get orgClassTypes() {
    return (this.model.class_types || []).filter(ct => ct.isOrg);
  }

  @action
  async updateField(field, event) {
    this.model.event[field] = event.target.value;
    if (field === "booking_type") {
      this.bookingType = event.target.value;
    }
    if (field === "organisation_id" && event.target.value) {
      try {
        const data = await ajax("/des/organisations/" + event.target.value + "/class-types.json");
        const orgTypes = (data.org_class_types || []).map(ct => ({
          id: ct.id,
          name: ct.name + " ★",
          isOrg: true
        }));
        const globalTypes = data.global_class_types || [];
        this.model.class_types = [
          ...globalTypes,
          ...orgTypes
        ];
      } catch (e) {
        // keep existing class types
      }
    }
  }

  @action
  updatePricing(field, event) {
    this.model.pricing[field] = event.target.value;
  }

  @action
  updatePricingType(event) {
    this.model.pricing.rule_type = event.target.value;
    this.pricingType = event.target.value;
  }

  @action
  addClass() {
    this.classes = [...this.classes, { class_type_id: "", capacity: 20 }];
  }

  @action
  updateClass(index, field, event) {
    const updated = this.classes.map((cls, i) => {
      if (i === index) {
        return { ...cls, [field]: event.target.value };
      }
      return cls;
    });
    this.classes = updated;
  }

  @action
  removeClass(index) {
    this.classes = this.classes.filter((_, i) => i !== index);
  }

  @action
  async saveEvent() {
    if (!this.model.event.title) {
      alert("Please enter an event title");
      return;
    }
    if (!this.model.event.organisation_id) {
      alert("Please select an organisation");
      return;
    }
    if (!this.model.event.title?.trim()) {
      alert("Please enter an event title");
      return;
    }
    if (!this.model.event.start_date) {
      alert("Please enter a start date");
      return;
    }
    if (this.model.event.end_date && this.model.event.start_date) {
      if (new Date(this.model.event.end_date) < new Date(this.model.event.start_date)) {
        alert("End date must be after start date");
        return;
      }
    }
    if (this.model.event.booking_closing_date && this.model.event.start_date) {
      if (new Date(this.model.event.booking_closing_date) > new Date(this.model.event.start_date)) {
        alert("Booking closing date must be before the event start date");
        return;
      }
    }
    if (this.classes.length === 0) {
      alert("Please add at least one class");
      return;
    }

    this.isSaving = true;
    try {
      const response = await ajax("/des/events.json", {
        type: "POST",
        data: {
          organisation_id: this.model.event.organisation_id,
          event: {
            title: this.model.event.title,
            description: this.description || this.model.event.description,
            organisation_id: this.model.event.organisation_id,
            event_type_id: this.model.event.event_type_id,
            start_date: this.model.event.start_date,
            end_date: this.model.event.end_date,
            booking_closing_date: this.model.event.booking_closing_date,
            location: this.model.event.location,
            google_maps_url: this.model.event.google_maps_url,
            refund_cutoff_days: this.model.event.refund_cutoff_days || 7,
            booking_type: this.model.event.booking_type,
            external_booking_url: this.model.event.external_booking_url,
            external_booking_details: this.model.event.external_booking_details,
          },
          classes: this.classes,
          pricing: this.model.pricing,
        },
      });
      this.router.transitionTo("event", response.id);
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.isSaving = false;
    }
  }
}
