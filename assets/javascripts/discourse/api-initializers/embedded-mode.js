import { apiInitializer } from "discourse/lib/api";

export default apiInitializer("1.0", (api) => {
  const params = new URLSearchParams(window.location.search);
  if (params.get("embedded_event") === "true") {
    document.body.classList.add("des-embedded-event");
  }
});
