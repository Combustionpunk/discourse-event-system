import Controller from "@ember/controller";

export default class MyMembershipsController extends Controller {
  formatDate(dateStr) {
    if (!dateStr) return "—";
    return new Date(dateStr).toLocaleDateString("en-GB", {
      day: "numeric",
      month: "short",
      year: "numeric",
    });
  }

  isExpiringSoon(dateStr) {
    if (!dateStr) return false;
    const expires = new Date(dateStr);
    const soon = new Date();
    soon.setDate(soon.getDate() + 30);
    return expires < soon && expires > new Date();
  }
}
