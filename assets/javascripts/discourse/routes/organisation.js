import Route from "@ember/routing/route";
import { ajax } from "discourse/lib/ajax";

export default class OrganisationRoute extends Route {
  async model(params) {
    const org = await ajax("/des/organisations/" + params.organisation_id + ".json");
    if (org.is_admin) {
      try {
        const classTypesData = await ajax("/des/organisations/" + params.organisation_id + "/class-types.json");
        org.global_class_types = classTypesData.global_class_types;
        org.org_class_types = classTypesData.org_class_types;
        org.manufacturers = classTypesData.manufacturers;
        org.drivelines = classTypesData.drivelines;
        org.chassis_types = classTypesData.chassis_types;
      } catch (e) {
        org.global_class_types = [];
        org.org_class_types = [];
        org.manufacturers = [];
        org.drivelines = [];
        org.chassis_types = [];
      }
    }
    return org;
  }
}
