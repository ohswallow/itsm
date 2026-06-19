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

// 전역 타이머 변수 (중복 클릭 방지용)
let copyToastTimeout;

window.addEventListener("phx:copy", (event) => {
  if ("clipboard" in navigator) {
    navigator.clipboard.writeText(event.detail.text).then(() => {
      const toast = document.getElementById("copy-toast");
      if (!toast) return;

      // 이전 타이머가 있다면 초기화
      if (copyToastTimeout) clearTimeout(copyToastTimeout);

      // 1. 나타나기
      toast.classList.remove("hidden"); // 일단 DOM에는 표시

      // 브라우저가 hidden 제거를 렌더링한 후 애니메이션 클래스를 적용하기 위해 requestAnimationFrame 사용
      requestAnimationFrame(() => {
        // KB 스타일 애니메이션 시작 상태 제거
        toast.classList.remove("translate-y-[-20px]", "opacity-0");
        // 실제 노출 상태 클래스 추가 (필요시 스타일 추가 정의)
        toast.classList.add("translate-y-0", "opacity-100");
      });

      // 2. 2.5초 후 사라지기 (금융권 알림은 조금 더 오래 보여주는 경향이 있음)
      copyToastTimeout = setTimeout(() => {
        // 사라지는 애니메이션 적용
        toast.classList.add("opacity-0");
        toast.classList.remove("opacity-100");

        // 애니메이션이 끝난 후 hidden 처리 (duration-300 고려)
        setTimeout(() => {
            toast.classList.add("hidden", "translate-y-[-20px]");
        }, 300);
      }, 2500);

    }).catch(err => {
      console.error("KB Style Copy Toast Failed: ", err);
      // 실패 시 로직 (예: 빨간색 토스트)을 여기에 추가할 수 있습니다.
    });
  }
});
