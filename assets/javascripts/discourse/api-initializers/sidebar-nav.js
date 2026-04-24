import { apiInitializer } from "discourse/lib/api";

export default apiInitializer("1.0", (api) => {
  // Add RC Racing links to user profile menu
  api.addQuickAccessProfileItem({
    className: "my-organisations-link",
    icon: "users",
    content: "🏢 My Organisations",
    href: "/my-organisations",
  });

  api.addQuickAccessProfileItem({
    className: "racing-profile-link",
    icon: "user",
    content: "🏎️ Racing Profile",
    href: "/racing-profile",
  });

  api.addQuickAccessProfileItem({
    className: "my-garage-link",
    icon: "car",
    content: "🚗 My Garage",
    href: "/my-garage",
  });

  api.addQuickAccessProfileItem({
    className: "my-bookings-link",
    icon: "ticket",
    content: "🎟️ My Bookings",
    href: "/my-bookings",
  });

  api.addQuickAccessProfileItem({
    className: "my-memberships-link",
    icon: "id-card",
    content: "🎫 My Memberships",
    href: "/my-memberships",
  });

  // Add sidebar section
  api.addSidebarSection(
    (BaseCustomSidebarSection, BaseCustomSidebarSectionLink) => {

      class RCLink extends BaseCustomSidebarSectionLink {
        constructor({ route, title }) {
          super(...arguments);
          this._route = route;
          this._title = title;
        }
        get name() { return this._route; }
        get route() { return this._route; }
        get title() { return this._title; }
        get text() { return this._title; }
      }

      class RCEventsSidebarSection extends BaseCustomSidebarSection {
        get name() { return "rc-events"; }
        get title() { return "RC Racing"; }
        get text() { return "RC Racing"; }
        get actionsIcon() { return null; }

        get links() {
          const user = api.getCurrentUser();
          const links = [
            new RCLink({ route: "events", title: "📅 Events" }),
            new RCLink({ route: "organisations", title: "🏢 Organisations" }),
            new RCLink({ route: "venues", title: "📍 Venues" }),
          ];
          if (user) {
            links.push(new RCLink({ route: "my-organisations", title: "🏢 My Organisations" }));
            links.push(new RCLink({ route: "racing-profile", title: "🏎️ My Racing Profile" }));
            links.push(new RCLink({ route: "my-garage", title: "🚗 My Garage" }));
            links.push(new RCLink({ route: "my-bookings", title: "🎟️ My Bookings" }));
            links.push(new RCLink({ route: "my-memberships", title: "🎫 My Memberships" }));
            if (user.admin) {
              links.push(new RCLink({ route: "des-admin", title: "⚙️ DES Admin" }));
            }
          }
          return links;
        }

        get displaySection() {
          return true;
        }
      }

      return RCEventsSidebarSection;
    }
  );
});
