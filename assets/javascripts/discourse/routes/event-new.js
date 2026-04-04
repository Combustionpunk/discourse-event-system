import Route from "@ember/routing/route";
import { ajax } from "discourse/lib/ajax";

export default class EventNewRoute extends Route {
  model() {
    return ajax("/des/organisations.json").then((response) => {
      const organisations = response.organisations || response;
      return {
        organisations: organisations.filter(o => o.status === "approved"),
        class_types: [],
        event: {
          title: "",
          description: "",
          organisation_id: "",
          event_type_id: "",
          start_date: "",
          end_date: "",
          booking_closing_date: "",
          location: "",
          google_maps_url: "",
          refund_cutoff_days: 7,
          booking_type: "internal",
          external_booking_url: "",
          external_booking_details: "",
        },
        classes: [],
        pricing: {
          rule_type: "tiered",
          first_class_price: "",
          subsequent_class_price: "",
          flat_price: "",
        }
      };
    }).then(async (model) => {
      const classTypes = await ajax("/des/class-types.json");
      model.class_types = classTypes.class_types || [];
      const eventTypes = await ajax("/des/event-types.json");
      model.event_types = eventTypes.event_types || [];
      return model;
    });
  }
}
