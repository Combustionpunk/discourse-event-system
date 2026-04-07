import Controller from "@ember/controller";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { inject as service } from "@ember/service";

export default class EventController extends Controller {
  @service currentUser;
  @service router;
  @tracked selectedClasses = [];
  @tracked isBooking = false;
  @tracked showCarSelection = false;
  @tracked eligibleCars = [];
  @tracked carSelections = {};
  @tracked familyExpanded = false;
  @tracked familySelections = {};

  _calculateForClasses(count, isMember, isJunior) {
    const pricing = this.model.pricing;
    if (!pricing || count === 0) return 0;

    let firstDiscount = 0;
    let subsequentDiscount = 0;

    if (isMember) {
      firstDiscount += parseFloat(pricing.member_first_class_discount || 0);
      subsequentDiscount += parseFloat(pricing.member_subsequent_discount || 0);
    }
    if (isJunior) {
      firstDiscount += parseFloat(pricing.junior_first_class_discount || 0);
      subsequentDiscount += parseFloat(pricing.junior_subsequent_discount || 0);
    }

    if (pricing.rule_type === "tiered") {
      const first = Math.max(parseFloat(pricing.first_class_price) - firstDiscount, 0);
      const subsequent = Math.max(parseFloat(pricing.subsequent_class_price) - subsequentDiscount, 0);
      return count === 1 ? first : first + subsequent * (count - 1);
    } else {
      const base = parseFloat(pricing.flat_price);
      const first = Math.max(base - firstDiscount, 0);
      const subsequent = Math.max(base - subsequentDiscount, 0);
      return count === 1 ? first : first + subsequent * (count - 1);
    }
  }

  get calculatedTotal() {
    const pricing = this.model.pricing;
    if (!pricing) return 0;

    const isMember = this.model.user_is_member || false;
    const isJunior = this.model.user_is_junior || false;

    // Primary user total
    let total = this._calculateForClasses(this.selectedClasses.length, isMember, isJunior);

    // Family member totals (family members share the membership so they are also members)
    const familySelections = this.familySelections;
    Object.keys(familySelections).forEach(userId => {
      const classIds = familySelections[userId] || [];
      if (classIds.length > 0) {
        total += this._calculateForClasses(classIds.length, isMember, false);
      }
    });

    return total;
  }

  get totalClassCount() {
    let count = this.selectedClasses.length;
    Object.values(this.familySelections).forEach(classIds => {
      count += (classIds || []).length;
    });
    return count;
  }

  get hasFamilySelections() {
    return Object.values(this.familySelections).some(ids => ids && ids.length > 0);
  }

  get maxClassesReached() {
    const max = this.model.max_classes_per_booking;
    if (!max) return false;
    return this.selectedClasses.length >= max;
  }

  get allCarsSelected() {
    return this.eligibleCars.every(cls => this.carSelections[cls.class_id]);
  }

  @action
  toggleClass(classId) {
    if (this.selectedClasses.includes(classId)) {
      this.selectedClasses = this.selectedClasses.filter((id) => id !== classId);
    } else {
      const max = this.model.max_classes_per_booking;
      if (max && this.selectedClasses.length >= max) {
        alert("You can only select a maximum of " + max + " class(es) for this event.");
        return;
      }
      this.selectedClasses = [...this.selectedClasses, classId];
    }
  }

  @action
  async joinWaitlist(classId) {
    if (!this.currentUser) {
      alert("Please log in to join the waitlist");
      return;
    }
    try {
      const response = await ajax("/des/waitlist.json", {
        type: "POST",
        data: {
          event_id: this.model.id,
          event_class_id: classId,
        },
      });
      alert("You have been added to the waitlist at position " + response.position + ". We will email you if a space becomes available!");
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  async publishEvent() {
    if (!window.confirm("Publish this event? It will become visible to all users.")) return;
    try {
      await ajax("/des/events/" + this.model.id + "/publish.json", {
        type: "POST",
      });
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  async bookEvent() {
    if (this.selectedClasses.length === 0) return;

    // Check if user has garage cars
    try {
      const response = await ajax("/des/bookings/eligible-cars.json", {
        data: {
          event_id: this.model.id,
          class_ids: this.selectedClasses,
        },
      });

      this.eligibleCars = response.classes;
      this.carSelections = {};

      // Auto-select if only one car eligible per class
      response.classes.forEach(cls => {
        if (cls.eligible_cars.length === 1) {
          this.carSelections = {
            ...this.carSelections,
            [cls.class_id]: cls.eligible_cars[0].id
          };
        }
      });

      this.showCarSelection = true;
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  selectCar(classId, event) {
    this.carSelections = {
      ...this.carSelections,
      [classId]: event.target.value
    };
  }

  @action
  toggleFamilySection() {
    this.familyExpanded = !this.familyExpanded;
  }

  @action
  toggleFamilyClass(userId, classId) {
    const current = { ...this.familySelections };
    const userClasses = current[userId] || [];

    if (userClasses.includes(classId)) {
      current[userId] = userClasses.filter((id) => id !== classId);
    } else {
      current[userId] = [...userClasses, classId];
    }

    this.familySelections = current;
  }

  @action
  cancelCarSelection() {
    this.showCarSelection = false;
    this.eligibleCars = [];
    this.carSelections = {};
  }

  @action
  async confirmBooking() {
    this.isBooking = true;
    try {
      const data = {
        event_id: this.model.id,
        class_ids: this.selectedClasses,
        car_selections: this.carSelections,
      };

      // Include family bookings if any selected
      if (this.hasFamilySelections) {
        const familyBookings = {};
        let index = 0;
        Object.keys(this.familySelections).forEach(userId => {
          const classIds = this.familySelections[userId];
          if (classIds && classIds.length > 0) {
            familyBookings[index] = {
              user_id: userId,
              class_ids: classIds,
            };
            index++;
          }
        });
        data.family_bookings = familyBookings;
      }

      const response = await ajax("/des/bookings.json", {
        type: "POST",
        data,
      });
      window.location.href = response.approval_url;
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.isBooking = false;
    }
  }
}
