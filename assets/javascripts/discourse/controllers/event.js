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
  @tracked familyEligibleCars = null;
  @tracked familyCarSelections = {};
  @tracked isWhosComingExpanded = false;
  @tracked showCalendarDropdown = false;


  get bookingClosed() {
    if (!this.model.booking_closing_date) return false;
    return new Date(this.model.booking_closing_date) < new Date();
  }

  get bookingDisabled() {
    return this.model.status === "cancelled" || this.bookingClosed;
  }

  get totalEntrantCount() {
    if (!this.model.public_entrants) return 0;
    let count = 0;
    this.model.public_entrants.forEach(cls => {
      count += (cls.entrants || []).length;
    });
    return count;
  }

  @action
  toggleWhosComingSection() {
    this.isWhosComingExpanded = !this.isWhosComingExpanded;
  }

  @action
  toggleCalendarDropdown() {
    this.showCalendarDropdown = !this.showCalendarDropdown;
  }

  get googleCalendarUrl() {
    const e = this.model;
    if (!e.start_date) return "#";
    const start = new Date(e.start_date);
    const end = e.end_date ? new Date(e.end_date) : new Date(start.getTime() + 4 * 60 * 60 * 1000);
    const fmt = (d) => d.toISOString().replace(/[-:]/g, "").replace(/\.\d{3}/, "");
    const dates = fmt(start) + "/" + fmt(end);
    const params = new URLSearchParams({
      action: "TEMPLATE",
      text: e.title,
      dates: dates,
      location: e.location || "",
      details: (e.description || "") + "\n\n" + window.location.origin + "/events/" + e.id
    });
    return "https://calendar.google.com/calendar/render?" + params.toString();
  }

  get outlookCalendarUrl() {
    const e = this.model;
    if (!e.start_date) return "#";
    const start = new Date(e.start_date).toISOString();
    const end = e.end_date ? new Date(e.end_date).toISOString() : new Date(new Date(e.start_date).getTime() + 4 * 60 * 60 * 1000).toISOString();
    const params = new URLSearchParams({
      rru: "addevent",
      subject: e.title,
      startdt: start,
      enddt: end,
      location: e.location || "",
      body: (e.description || "") + "\n\n" + window.location.origin + "/events/" + e.id,
      path: "/calendar/action/compose"
    });
    return "https://outlook.live.com/calendar/0/deeplink/compose?" + params.toString();
  }

  @action
  downloadICS() {
    const e = this.model;
    if (!e.start_date) return;
    const fmt = (d) => new Date(d).toISOString().replace(/[-:]/g, "").replace(/\.\d{3}/, "");
    const start = fmt(e.start_date);
    const end = e.end_date ? fmt(e.end_date) : fmt(new Date(new Date(e.start_date).getTime() + 4 * 60 * 60 * 1000));
    const ics = [
      "BEGIN:VCALENDAR",
      "VERSION:2.0",
      "PRODID:-//RC Event System//EN",
      "CALSCALE:GREGORIAN",
      "METHOD:PUBLISH",
      "BEGIN:VEVENT",
      "SUMMARY:" + (e.title || ""),
      "DTSTART:" + start,
      "DTEND:" + end,
      "LOCATION:" + (e.location || ""),
      "DESCRIPTION:" + (e.description || "").replace(/\n/g, "\\n"),
      "URL:" + window.location.origin + "/events/" + e.id,
      "END:VEVENT",
      "END:VCALENDAR"
    ].join("\r\n");
    const blob = new Blob([ics], { type: "text/calendar;charset=utf-8" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = (e.title || "event").replace(/[^a-z0-9]/gi, "-").toLowerCase() + ".ics";
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  }



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

  get noClassesSelected() {
    return this.selectedClasses.length === 0 && !this.hasFamilySelections;
  }

  get maxClassesReached() {
    const max = this.model.max_classes_per_booking;
    if (!max) return false;
    return this.selectedClasses.length >= max;
  }

  get allCarsSelected() {
    // Check parent's cars are selected
    const parentOk = this.eligibleCars.every(cls => this.carSelections[cls.class_id]);
    if (!parentOk) return false;

    // Check family members' cars are selected
    if (this.familyEligibleCars) {
      for (const entry of this.familyEligibleCars) {
        for (const cls of entry.classes) {
          if (!this.familyCarSelections[`${entry.user_id}_${cls.class_id}`]) {
            return false;
          }
        }
      }
    }
    return true;
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
    if (this.selectedClasses.length === 0 && !this.hasFamilySelections) return;

    try {
      // Fetch eligible cars for parent's classes (uses parent's garage)
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

      // Fetch eligible cars for family members' classes (also uses parent's garage)
      this.familyEligibleCars = null;
      this.familyCarSelections = {};

      if (this.hasFamilySelections) {
        const familyEntries = [];
        for (const userId of Object.keys(this.familySelections)) {
          const classIds = this.familySelections[userId];
          if (classIds && classIds.length > 0) {
            const familyResponse = await ajax("/des/bookings/eligible-cars.json", {
              data: {
                event_id: this.model.id,
                class_ids: classIds,
              },
            });
            const member = this.model.family_members.find(m => String(m.user_id) === String(userId));
            familyEntries.push({
              user_id: userId,
              username: member ? member.username : `User ${userId}`,
              classes: familyResponse.classes,
            });

            // Auto-select if only one car eligible
            familyResponse.classes.forEach(cls => {
              if (cls.eligible_cars.length === 1) {
                this.familyCarSelections = {
                  ...this.familyCarSelections,
                  [`${userId}_${cls.class_id}`]: cls.eligible_cars[0].id
                };
              }
            });
          }
        }
        this.familyEligibleCars = familyEntries;
      }

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
  selectFamilyCar(userId, classId, event) {
    this.familyCarSelections = {
      ...this.familyCarSelections,
      [`${userId}_${classId}`]: event.target.value
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
    this.familyEligibleCars = null;
    this.familyCarSelections = {};
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
            // Gather car selections for this family member
            const memberCarSelections = {};
            classIds.forEach(classId => {
              const key = `${userId}_${classId}`;
              if (this.familyCarSelections[key]) {
                memberCarSelections[classId] = this.familyCarSelections[key];
              }
            });
            familyBookings[index] = {
              user_id: userId,
              class_ids: classIds,
              car_selections: memberCarSelections,
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
