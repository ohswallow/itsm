import  LocalTime  from './LocalTime';

const Calendar = {};

Calendar.DateGrid = {
  mounted() {
    this.init();

    this.el.addEventListener("click", e => {
      const dateCell = e.target.closest("[data-date]");
      if (!dateCell || dateCell.hasAttribute("data-disabled")) return;

      const prevSelected = this.el.querySelector(".selected-date");
      prevSelected?.classList.remove(...Calendar.selectDateClass);
      dateCell.classList.add(...Calendar.selectDateClass);

      const [dt, ctx] = Calendar.getDtAndContext(this.el);
      if (this.el.dataset.showTime === "false") {
        const popupId = this.el.id.replace("-calendar-grid", "-calendar-popup");
        window.liveSocket?.execJS(this.el, `[[ "hide", { "to": "#${popupId}" } ]]`);
      } else {
        if (!ctx.hInput.value) {
          Calendar.updateTime(ctx.hInput, dt);
        }

        if(!ctx.mInput.value) {
          Calendar.updateTime(ctx.mInput, dt);
        }
      }
      Calendar.updateDateTime(ctx.sInput, dt);
      this.pushEventTo(this.el.getAttribute("phx-target"), "selected_date_time", { datetime: dt.toISOString() });
    });
  },
  updated() {
    this.init();
  },

  init() {
    if (!this.el.querySelector(".today-active")) {
      Calendar.setTodayDate(this.el);
    }

    const utcValue = this.el.getAttribute("utc-value");
    const selectedDate = this.el.querySelector(".selected-date");
    if (utcValue && !selectedDate) {
      const rawDate = LocalTime.getValue(utcValue, "datetime");
      const targetDate = new Date(rawDate);
      const year = targetDate.getFullYear();
      const month = String(targetDate.getMonth() + 1).padStart(2, "0");
      const date = String(targetDate.getDate()).padStart(2, "0");
      const targetDateString = `${year}-${month}-${date}`;
      const targetElement = this.el.querySelector(`[data-date="${targetDateString}"]`);
      targetElement?.classList.add(...Calendar.selectDateClass);
    }
  }
};

Calendar.Input = {
  mounted() {
    LocalTime.renderElement(this.el);
    this.el.addEventListener("blur", e => {
      const [dt, ctx] = Calendar.getDtAndContext(this.el);
      if (e.target.value !== ctx.mInput.value || e.target.value !== ctx.hInput.value) {
        const container = this.el.closest("[data-calendar-root]")
        const today = container.querySelector(".today-active");
        if (!ctx.sInput.selectDate && today) {
          today.classList.add(...Calendar.selectDateClass)
          ctx.sInput.selectDate = today.dataset.date;
        }
      }
      Calendar.updateTime(ctx.hInput, dt);
      Calendar.updateTime(ctx.mInput, dt);
      Calendar.updateDateTime(ctx.sInput, dt);

      this.pushEventTo(this.el.getAttribute("phx-target"), "selected_date_time", { datetime: dt.toISOString() });
    });
  },
};

Calendar.Toggle = {
  updated() {
    const popupId = this.el.id.replace("datepicker-input-", "") + "-calendar-popup";
    const popup = document.getElementById(popupId);
    const dateEls = popup.querySelectorAll('[data-date]');
    dateEls.forEach(el => Calendar.updateDateElementStatus(el));

    if (!popup.querySelector(".today-active")) {
      Calendar.setTodayDate(popup);
    }
  }
};

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

  let dt = baseDate ? new Date(baseDate) : new Date();
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

Calendar.getDtAndContext = (element) => {
  const container = element.closest("[data-calendar-root]");
  const ctx = Calendar.getContext(container);
  if (!ctx || !ctx.sInput) return null;
  const baseDate = ctx.selectedDateEl ? ctx.selectedDateEl.dataset.date : ctx.sInput.selectDate;
  ctx.sInput.selectDate = baseDate;
  const dt = Calendar.clampDateTime(ctx.hInput, ctx.mInput, ctx.sInput, baseDate);
  if (!dt || isNaN(dt.getTime())) return null;
  return [dt, ctx];
};

Calendar.updateDateElementStatus = (el) => {
  const isDisabled = el.hasAttribute('data-disabled') && el.getAttribute('data-disabled') !== "false";

  if (isDisabled) {
    el.classList.remove(...Calendar.enabledClasses);
    el.classList.add(...Calendar.disabledClasses);
  } else {
    el.classList.remove(...Calendar.disabledClasses);
    el.classList.add(...Calendar.enabledClasses);
  }
};

Calendar.updateDateTime = (sInput, dt) => {
  const isoString = dt.toISOString()
  if (sInput.value !== isoString) {
    sInput.value = isoString;
    sInput.setAttribute("value", isoString);
    sInput.dispatchEvent(new Event("input", { bubbles: true }));
  }
}

Calendar.updateTime =(input, dt) => {
  if (!input) return;
  const format = input.getAttribute("format");
  const targetValue = String((format === "hour") ? dt.getHours() : (format === "minute") ? dt.getMinutes() : 0).padStart(2, "0");
  input.value = targetValue;
  input.setAttribute("utc-value", dt.toISOString());
  input.dispatchEvent(new Event("input", { bubbles: true }));
}

Calendar.setTodayDate = (e) => {
  const today = new Date();
  const year = today.getFullYear();
  const month = String(today.getMonth() + 1).padStart(2, '0');
  const day = String(today.getDate()).padStart(2, '0');
  const todayStr = `${year}-${month}-${day}`;
  e.querySelector(`[data-date="${todayStr}"]`)?.classList.add(...Calendar.todayDateClass);
}

Calendar.selectDateClass = ["bg-indigo-600", "text-white", "shadow-md", "selected-date"];
Calendar.todayDateClass = ["bg-blue-100", "border-blue-500", "today-active"];
Calendar.disabledClasses = ["text-gray-300", "cursor-not-allowed", "opacity-50"];
Calendar.enabledClasses = ["cursor-pointer", "hover:bg-gray-100"];

export default Calendar;
