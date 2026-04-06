import Controller from "@ember/controller";

export default class MyOrganisationsController extends Controller {
  formatDate(dateStr) {
    if (!dateStr) return "—";
    return new Date(dateStr).toLocaleDateString("en-GB", {
      day: "numeric",
      month: "short",
      year: "numeric",
    });
  }
}
