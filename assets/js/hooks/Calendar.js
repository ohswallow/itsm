import LocalTime from "./LocalTime";

const Calendar = {};

Calendar.getContext = (container) => {
  if (!container) return null;
  const uniqueId = container.id.replace("datepicker-container-", "");
  return {
    uniqueId,
    hInput: document.getElementById(`${uniqueId}-selected_date_time-hour`),
    mInput: document.getElementById(`${uniqueId}-selected_date_time-minute`),
    sInput: document.getElementById(`selected_date_time-${uniqueId}`),
    selectedDateEl: container.querySelector(".selected-date")
  };
};

Calendar.clampDateTime = (hInput, mInput, sInput, baseDate) => {
  let h = 0;
  let m = 0;
  if (hInput && mInput) {
    h = parseInt(hInput.value, 10) || 0;
    m = parseInt(mInput.value, 10) || 0;

    const hMinLimit = parseInt(hInput.min, 10) || 0;
    const hMaxLimit = parseInt(hInput.max, 10) || 23;
    const mMinLimit = parseInt(mInput.min, 10) || 0;
    const mMaxLimit = parseInt(mInput.max, 10) || 59;

    h = Math.min(hMaxLimit, Math.max(hMinLimit, h));
    m = Math.min(mMaxLimit, Math.max(mMinLimit, m));
  }

  let dt = new Date(baseDate);
  dt.setHours(h, m, 0, 0);
  if (sInput.min) {
    const dtmin = new Date(sInput.min);
    if (dtmin && !isNaN(dtmin.getTime()) && dt < dtmin) {
      dt = dtmin;
      }

  }
  if (sInput.max) {
    const dtmax = new Date(sInput.max);
    if (dtmax && !isNaN(dtmax.getTime()) && dt > dtmax) {
      dt = dtmax;
      }
  }
  return new Date(dt);
}

Calendar.updateSelectedDateTime = (container, phxTarget, pushEventTo) => {
  const ctx = Calendar.getContext(container);
  if (!ctx || !ctx.sInput || !ctx.selectedDateEl) return null;

  const dt = Calendar.clampDateTime(ctx.hInput, ctx.mInput, ctx.sInput, ctx.selectedDateEl.dataset.date);
  if (!dt || isNaN(dt.getTime())) return null;
  const isoString = dt.toISOString();

  if (ctx.sInput.value !== isoString) {
    ctx.sInput.value = isoString;
    ctx.sInput.setAttribute("value", isoString);
    ctx.sInput.dispatchEvent(new Event("input", { bubbles: true }));
  }

  [ctx.hInput, ctx.mInput].forEach(input => {
    if (input) {
      const format = input.getAttribute("format");
      input.value = String(format === "hour") ? dt.getHours() : (format === "minute") ? dt.getMinutes() : 0
      input.setAttribute("utc-value", isoString);
      LocalTime.renderElement(input);
    }
  });

  pushEventTo(phxTarget, "selected_date_time", { datetime: isoString });
};

Calendar.updateDateElementStatus = (el) => {
  const isDisabled = el.hasAttribute('data-disabled') && el.getAttribute('data-disabled') !== "false";

  const disabledClasses = ["text-gray-300", "cursor-not-allowed", "opacity-50"];
  const enabledClasses = ["cursor-pointer", "hover:bg-gray-100"];

  if (isDisabled) {
    el.classList.remove(...enabledClasses);
    el.classList.add(...disabledClasses);
  } else {
    el.classList.remove(...disabledClasses);
    el.classList.add(...enabledClasses);
  }
};

Calendar.DateGrid = {
  mounted() {
    this.el.addEventListener("click", e => {
      const dateCell = e.target.closest("[data-date]");
      if (!dateCell || dateCell.hasAttribute("data-disabled")) return;

      const prevSelected = this.el.querySelector(".selected-date");
      if (prevSelected) {
        prevSelected.classList.remove("bg-indigo-600", "text-white", "shadow-md", "selected-date");
      }
      dateCell.classList.add("bg-indigo-600", "text-white", "shadow-md", "selected-date");

      Calendar.updateSelectedDateTime(
        this.el.closest("[data-calendar-root]"),
        this.el.getAttribute("phx-target"),
        this.pushEventTo.bind(this)
      );

      if (this.el.dataset.showTime === "false") {
        const popupId = this.el.id.replace("-calendar-grid", "-calendar-popup");
        if (window.liveSocket) window.liveSocket.execJS(this.el, `[[ "hide", { "to": "#${popupId}" } ]]`);
      }
    });
  },
};

Calendar.Input = {
  mounted() {
    LocalTime.renderElement(this.el);
    this.el.addEventListener("input", e => {
      if (!e.inputType) {
        Calendar.updateSelectedDateTime(
          this.el.closest("[data-calendar-root]"),
          this.el.getAttribute("phx-target"),
          this.pushEventTo.bind(this)
        );
      }
    });

    this.el.addEventListener("blur", () => {
      Calendar.updateSelectedDateTime(
        this.el.closest("[data-calendar-root]"),
        this.el.getAttribute("phx-target"),
        this.pushEventTo.bind(this)
      );
    });
  },
  updated() {
    if (document.activeElement !== this.el) {
      LocalTime.renderElement(this.el);
    }
  },
};

Calendar.Toggle = {
  mounted() {
    const popupId = this.el.id.replace("datepicker-input-", "") + "-calendar-popup";
    const popup = document.getElementById(popupId);

    popup.addEventListener("calendar:opened", () => {
      const dateEls = popup.querySelectorAll('[data-date]');
      dateEls.forEach(el => Calendar.updateDateElementStatus(el));
    });
  },
  updated() {
    const popupId = this.el.id.replace("datepicker-input-", "") + "-calendar-popup";
    const popup = document.getElementById(popupId);
    const dateEls = popup.querySelectorAll('[data-date]');
    dateEls.forEach(el => Calendar.updateDateElementStatus(el));
  }
};

export default Calendar;
