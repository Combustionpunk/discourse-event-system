import Route from "@ember/routing/route";

export default class OrganisationNewRoute extends Route {
  model() {
    return {
      name: "",
      description: "",
      email: "",
      phone: "",
      website: "",
      address: "",
      google_maps_url: "",
      paypal_email: "",
    };
  }
}
