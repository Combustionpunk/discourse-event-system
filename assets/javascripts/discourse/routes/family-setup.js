import Route from "@ember/routing/route";
import { ajax } from "discourse/lib/ajax";

export default class FamilySetupRoute extends Route {
  async model(params) {
    try {
      const data = await ajax(`/des/memberships/${params.membership_id}/family-members.json`);
      return {
        membership_id: params.membership_id,
        max_members: data.max_members || 1,
        organisation_name: data.organisation_name,
        family_members: data.family_members || []
      };
    } catch (e) {
      return {
        error: e.jqXHR?.responseJSON?.error || "Failed to load family setup",
        membership_id: params.membership_id
      };
    }
  }

  setupController(controller, model) {
    super.setupController(controller, model);
    controller.setup(model);
  }
}
