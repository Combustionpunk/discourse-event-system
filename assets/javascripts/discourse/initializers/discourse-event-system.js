import { withPluginApi } from "discourse/lib/plugin-api";
export default {
  name: "discourse-event-system",
  initialize() {
    withPluginApi("0.8.31", (api) => {
      api.addCommunitySectionLink((baseSectionLink) => {
        return class EventsSectionLink extends baseSectionLink {
          name = "events";
          route = "events";
          text = "Upcoming Events";
          title = "Upcoming Events";
          defaultPrefixValue = "calendar-days";
        };
      });

      api.addCommunitySectionLink((baseSectionLink) => {
        return class MyBookingsSectionLink extends baseSectionLink {
          name = "my-bookings";
          route = "my-bookings";
          text = "My Bookings";
          title = "My Bookings";
          defaultPrefixValue = "ticket";
        };
      });

    });
  },
};
