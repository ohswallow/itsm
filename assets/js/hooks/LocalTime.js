const LocalTime = {}

LocalTime.pad = (n) => String(n).padStart(2, '0');

LocalTime.getValue = (isoString, format) => {
  if (!isoString) return "";
  const dt = new Date(isoString);
  if (isNaN(dt)) return "";

  const pad = (n) => String(n).padStart(2, '0');

  const map = {
    YYYY: dt.getFullYear(),
    YY: String(dt.getFullYear()).slice(-2),
    MM: pad(dt.getMonth() + 1),
    M: dt.getMonth() + 1,
    DD: pad(dt.getDate()),
    D: dt.getDate(),
    HH: pad(dt.getHours()),
    H: dt.getHours(),
    mm: pad(dt.getMinutes()),
    m: dt.getMinutes(),
    ss: pad(dt.getSeconds()),
    s: dt.getSeconds(),
  };

  const presets = {
    "datetime": "YYYY-MM-DD HH:mm",
    "date": "YYYY-MM-DD",
    "time": "HH:mm",
    "hour": "HH",
    "minute": "mm",
    "second": "ss"
  };
  const pattern = presets[format] || format;

  return pattern.replace(/YYYY|YY|MM|M|DD|D|HH|H|mm|m|ss|s/g, (matched) => map[matched]);
};

LocalTime.renderElement = (el) => {
  const format = el.getAttribute("format") || "datetime";
  const source = el.getAttribute("utc-value") || el.textContent;
  const result = LocalTime.getValue(source, format);
  if (el.tagName === "INPUT") {
    if (el.value !== String(result)) {
      el.value = result;
    }
  } else {
   if (el.textContent !== String(result)) {
      el.textContent = result;
    }
  }
};

LocalTime.ToLocaleString = {
  mounted() {
    // 요소의 textContent(UTC 시간)를 가져와서 Date 객체로 변환
    // 서버에서 "2025-11-19T10:30:00Z" 형식으로 내려준다고 가정
    const dt = new Date(this.el.getAttribute("datetime"));

    // 옵션 설정: 초(second)를 제외하고 시, 분까지만 설정
    const options = {
      year: 'numeric',   // 2025년
      month: 'numeric',  // 11월
      day: 'numeric',    // 20일
      hour: '2-digit',   // 10시
      minute: '2-digit', // 51분
      // second: '2-digit' // <-- 이 줄이 없으면 초는 안 나옵니다!
    };

    // 첫 번째 인자에 undefined를 넣으면 브라우저 기본 언어 설정(사용자 로케일)을 따릅니다.
    // 한국어 강제 설정을 원하시면 'ko-KR'을 넣으세요.
    this.el.textContent = dt.toLocaleString(undefined, options);

    this.el.classList.remove("invisible")
  }
};

LocalTime.ToLocale = {
  mounted() {
    LocalTime.renderElement(this.el);
  },
  updated() {
    if (document.activeElement !== this.el) {
      LocalTime.renderElement(this.el);
    }
  }
};

LocalTime.GridToLocale = {
  getLocalTime(isoString) {
    const date = new Date(isoString);
    return isNaN(date) ? null : date;
  },
  findLocalSelectedEl(hook) {
    const source = hook.el.getAttribute("utc-value");
    const localTarget = LocalTime.GridToLocale.getLocalTime(source);
    if (!localTarget) return null;

    return Array.from(hook.el.querySelectorAll("[data-date]")).find(el => {
      const cellDate = new Date(el.dataset.date);
      return (
        localTarget.getFullYear() === cellDate.getFullYear() &&
        localTarget.getMonth() === cellDate.getMonth() &&
        localTarget.getDate() === cellDate.getDate()
      );
    });
  }
};

export default LocalTime;
