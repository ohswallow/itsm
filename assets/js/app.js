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
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import {hooks as colocatedHooks} from "phoenix-colocated/itsm"
import topbar from "../vendor/topbar"
import LocalTime from "./hooks/LocalTime.hooks"
import Calendar from "./hooks/Calendar.hooks"
import InputSelect from "./hooks/InputSelect.hooks"
import live_select from "live_select"

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: {
    ...colocatedHooks,
    "LocalTime.ToLocale": LocalTime.ToLocale,
    "Calendar.Toggle": Calendar.Toggle,
    "Calendar.Input": Calendar.Input,
    "Calendar.DateGrid": Calendar.DateGrid,
    "InputSelect.selectAll": InputSelect.selectAll,
    "LocalTime.ToLocaleString": LocalTime.ToLocaleString,
    ...live_select
  },
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())
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
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({detail: reloader}) => {
    // Enable server log streaming to client.
    // Disable with reloader.disableServerLogs()
    reloader.enableServerLogs()

    // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
    //
    //   * click with "c" key pressed to open at caller location
    //   * click with "d" key pressed to open at function component definition location
    let keyDown
    window.addEventListener("keydown", e => keyDown = e.key)
    window.addEventListener("keyup", _e => keyDown = null)
    window.addEventListener("click", e => {
      if(keyDown === "c"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if(keyDown === "d"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}

