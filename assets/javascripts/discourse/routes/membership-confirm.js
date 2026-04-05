import Route from "@ember/routing/route";
import { ajax } from "discourse/lib/ajax";

export default class MembershipConfirmRoute extends Route {
  async model(params) {
    try {
      const response = await ajax("/des/memberships/" + params.membership_id + "/confirm.json", {
        type: "POST"
      });
      return { success: true, organisation: response.organisation };
    } catch (e) {
      return { 
        success: false, 
        error: e.jqXHR?.responseJSON?.error || "Payment confirmation failed" 
      };
    }
  }
}
