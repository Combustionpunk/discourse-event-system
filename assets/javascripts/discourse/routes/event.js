import Route from "@ember/routing/route";
import { ajax } from "discourse/lib/ajax";
import DiscourseURL from "discourse/lib/url";

export default class EventRoute extends Route {
  // Mirrors FrontendController#event: members are sent to the event's topic.
  async model(params) {
    let event;
    try {
      event = await ajax(`/des/events/${params.event_id}.json`);
    } catch {
      return { unavailable: true };
    }
    if (!event.is_admin) {
      if (event.topic_url) {
        DiscourseURL.routeTo(event.topic_url, { replaceURL: true });
      }
      return { unavailable: true };
    }
    const date = new Date(event.start_date);
    event.formatted_date = date.toLocaleDateString("en-GB", {
      weekday: "long",
      year: "numeric",
      month: "long",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });

    try {
      const entrantsData = await ajax(`/des/events/${params.event_id}/public-entrants.json`);
      const statusOrder = { confirmed: 0, pending: 1, waitlist: 2, cancelled: 3 };
      event.public_entrants = (entrantsData.classes || []).map(cls => {
        const sorted = (cls.entrants || []).slice().sort((a, b) => {
          const sa = statusOrder[a.status] ?? 99;
          const sb = statusOrder[b.status] ?? 99;
          if (sa !== sb) return sa - sb;
          return a.username.localeCompare(b.username);
        });
        return {
          id: cls.id,
          name: cls.name,
          entrants: sorted
        };
      });
    } catch {
      event.public_entrants = [];
    }


    return event;
  }

  setupController(controller, model) {
    super.setupController(controller, model);
    if (!model.unavailable && model.expects_results) {
      controller.loadResults();
    }
  }
}
