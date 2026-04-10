// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";
import MaintainHeight from "./hooks/MaintainHeight";
import SortableInputsFor from "./hooks/SortableInputsFor";
import live_select from "live_select";
import Raty from "../vendor/raty";
import LocalTime from "./hooks/LocalTime";
import InputSelect from "./hooks/InputSelect";
import Calendar from "./hooks/Calendar";
// import RatyHook from "./hooks/raty_hook";

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {
  hooks: {
    MaintainHeight,
    SortableInputsFor,
    ...live_select,
    // Raty: RatyHook,
    "InputSelect.selectAll": InputSelect.selectAll,
    "LocalTime.ToLocaleString": LocalTime.ToLocaleString,
    "LocalTime.ToLocale": LocalTime.ToLocale,
    "LocalTime.GridToLocale": LocalTime.GridToLocale,
    "Calendar.DateGrid": Calendar.DateGrid,
    "Calendar.Input": Calendar.Input,
    "Calendar.Toggle": Calendar.Toggle
  },
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  // heartbeatIntervalMs: 10000  // 10초마다
});

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
// window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());
window.addEventListener("phx:page-loading-stop", (_info) => {
  topbar.hide();

  const ratyEl = document.querySelector("[data-raty]");

  if (ratyEl && ratyEl.childElementCount === 0) {
    const raty = new Raty(ratyEl, { path: "/images", half: true });

    raty.init();
  }
});

window.addEventListener("phx:common_code_all_reloaded", (e) => {
  const allData = e.detail;
  const allElements = document.querySelectorAll("[data-common-code]");

  allElements.forEach(el => {
    const key = el.getAttribute("data-common-code");
    if (allData[key]) {
      const newLabel = allData[key];

      if (el.innerText !== newLabel) {
        el.innerText = newLabel;
        el.classList.add("bg-yellow-200", "transition-all", "duration-0");

        setTimeout(() => {
          el.classList.replace("duration-0", "duration-1000");
          el.classList.remove("bg-yellow-200");
        }, 1000);

        setTimeout(() => {
          el.classList.remove("transition-all", "duration-1000");
        }, 1200);
      }
    }
  });
});

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
