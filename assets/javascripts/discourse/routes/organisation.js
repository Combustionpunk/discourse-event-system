import Route from "@ember/routing/route";
import { ajax } from "discourse/lib/ajax";

export default class OrganisationRoute extends Route {
  async model(params) {
    const org = await ajax("/des/organisations/" + params.organisation_id + ".json");
    if (org.is_admin) {
      try {
        const [classTypesData, membershipData] = await Promise.all([
          ajax("/des/organisations/" + params.organisation_id + "/class-types.json"),
          ajax("/des/organisations/" + params.organisation_id + "/membership-types.json")
        ]);
        org.membership_types = membershipData.membership_types || [];
        org.global_class_types = classTypesData.global_class_types;
        org.org_class_types = classTypesData.org_class_types;
        org.manufacturers = classTypesData.manufacturers;
        org.approved_models = classTypesData.approved_models || [];
        org.drivelines = classTypesData.drivelines;
        org.chassis_types = classTypesData.chassis_types;
      } catch (e) {
        org.global_class_types = [];
        org.org_class_types = [];
        org.manufacturers = [];
        org.approved_models = [];
        org.drivelines = [];
        org.chassis_types = [];
      }
    }
    return org;
  }
}
