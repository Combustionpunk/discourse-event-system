import { apiInitializer } from "discourse/lib/api";
import EventBookingWidget from "../components/event-booking-widget";

export default apiInitializer("1.0", (api) => {
  api.renderAfterWrapperOutlet("post-article", EventBookingWidget);
});
