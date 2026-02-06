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
import { InputSelect } from "./hooks/InputSelect";
// import RatyHook from "./hooks/raty_hook";

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {
  hooks: {
    MaintainHeight,
    SortableInputsFor,
    ...live_select,
    LocalTime,
    // Raty: RatyHook,
    "InputSelect.selectAll": InputSelect.selectAll,
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

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
