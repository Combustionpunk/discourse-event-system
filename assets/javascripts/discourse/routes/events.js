import Route from "@ember/routing/route";
import { ajax } from "discourse/lib/ajax";

export default class EventsRoute extends Route {
  queryParams = {
    filter: { refreshModel: true },
    organisation_id: { refreshModel: true },
    event_type_id: { refreshModel: true },
  };

  async model(params) {
    const data = {};
    if (params.filter) data.filter = params.filter;
    if (params.organisation_id) data.organisation_id = params.organisation_id;
    if (params.event_type_id) data.event_type_id = params.event_type_id;

    const response = await ajax("/des/events.json", { data });
    const events = (response.events || []).map((event) => {
      const date = new Date(event.start_date);
      event.formatted_date = date.toLocaleDateString("en-GB", {
        weekday: "long",
        year: "numeric",
        month: "long",
        day: "numeric",
        hour: "2-digit",
        minute: "2-digit",
      });
      return event;
    });

    return {
      events,
      organisations: response.organisations || [],
      event_types: response.event_types || [],
    };
  }
}
