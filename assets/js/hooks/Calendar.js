import LocalTime from "./LocalTime";

const Calendar = {};

Calendar.updateSelectedDateTime = (container, phxTarget, pushEventTo) => {
  const selectedDateEl = container.querySelector(".selected-date");
  const gridEl = container.querySelector("[phx-hook='Calendar.DateGrid']");
  const baseSource = selectedDateEl ? selectedDateEl.dataset.date : gridEl.getAttribute("utc-value");

  const dt = new Date(baseSource);
  if (isNaN(dt)) return null;

  const hInput = container.querySelector('input[format="hour"]');
  const mInput = container.querySelector('input[format="minute"]');

  if (hInput && mInput) {
    dt.setHours(parseInt(hInput.value, 10) || 0);
    dt.setMinutes(parseInt(mInput.value, 10) || 0);
    dt.setSeconds(0);
  }

  const isoString = dt.toISOString();

  const selectedDateTimeId = container.id.replace("datepicker-container-", "selected_date_time-");
  const selectedDateTime = document.getElementById(selectedDateTimeId);

  if (selectedDateTime) {
    selectedDateTime.value = isoString;
    selectedDateTime.setAttribute("value", isoString);
    selectedDateTime.dispatchEvent(new Event("input", { bubbles: true }));
  }

  pushEventTo(phxTarget, "selected_date_time", { datetime: isoString });

  return isoString;
};

Calendar.updateDateElementStatus = (el) => {
    if (!el) return;

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

      this.highlightDate(dateCell);

      const container = this.el.closest("[data-calendar-root]");
      Calendar.updateSelectedDateTime(
        container,
        this.el.getAttribute("phx-target"),
        this.pushEventTo.bind(this)
      );

      if (this.el.dataset.showTime === "false") {
        const popupId = this.el.id.replace("-calendar-grid", "-calendar-popup");
        if (window.liveSocket) window.liveSocket.execJS(this.el, `[[ "hide", { "to": "#${popupId}" } ]]`);
      }
    });

    this.applySelection();
    this.syncAllDatesStatus();
  },

  syncAllDatesStatus() {
    const dateEls = this.el.querySelectorAll('[id*="-date-"]');
    dateEls.forEach(el => Calendar.updateDateElementStatus(el));
  },

  highlightDate(el) {
    this.el.querySelectorAll("[data-date]").forEach(cell => {
      cell.classList.remove("bg-indigo-600", "text-white", "shadow-md", "selected-date");
    });

    if (el) {
      el.classList.add("bg-indigo-600", "text-white", "shadow-md", "selected-date");
    }
  },

  applySelection() {
    const currentEl = LocalTime.GridToLocale.findLocalSelectedEl(this);
    this.highlightDate(currentEl);
  }
};

Calendar.Input = {
  mounted() {
    LocalTime.renderElement(this.el);
    this.el.addEventListener("input", e => {
      const container = this.el.closest("[data-calendar-root]");
      if (!container) return;

      Calendar.updateSelectedDateTime(container, this.el.getAttribute("phx-target"), this.pushEventTo.bind(this));
    });
  },
  updated() {
    if (document.activeElement !== this.el) {
      LocalTime.renderElement(this.el);
    }
  }
};

Calendar.Toggle = {
  mounted() {
    const popupId = this.el.id.replace("datepicker-input-", "") + "-calendar-popup";
    const popup = document.getElementById(popupId);

    popup.addEventListener("calendar:opened", () => {
      const dateEls = popup.querySelectorAll('[data-date]');
      dateEls.forEach(el => Calendar.updateDateElementStatus(el));
    });
  }
};

export default Calendar;
