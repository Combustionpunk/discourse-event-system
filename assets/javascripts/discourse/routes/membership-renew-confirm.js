import Route from "@ember/routing/route";
import { ajax } from "discourse/lib/ajax";
import { inject as service } from "@ember/service";

export default class MembershipRenewConfirmRoute extends Route {
  @service router;

  async model(params) {
    try {
      const response = await ajax("/des/memberships/" + params.membership_id + "/confirm-renewal.json", {
        type: "POST"
      });
      return { success: true, organisation: response.organisation, expires_at: response.expires_at };
    } catch (e) {
      return { success: false, error: e.jqXHR?.responseJSON?.error || "Renewal confirmation failed" };
    }
  }
}
