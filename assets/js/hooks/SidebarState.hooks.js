const SidebarState = {
  mounted() {
    this.storageKey = "itsm:desktop-sidebar-open";
    this.desktopQuery = window.matchMedia("(min-width: 1024px)");

    this.restoreState();

    this.handleChange = () => {
      // 모바일 Drawer 상태는 저장하지 않는다.
      if (!this.desktopQuery.matches) return;

      localStorage.setItem(this.storageKey, String(this.el.checked));
    };

    this.handleBreakpointChange = () => {
      this.restoreState();
    };

    this.el.addEventListener("change", this.handleChange);
    this.desktopQuery.addEventListener("change", this.handleBreakpointChange);
  },

  destroyed() {
    this.el.removeEventListener("change", this.handleChange);

    this.desktopQuery.removeEventListener(
      "change",
      this.handleBreakpointChange,
    );
  },

  restoreState() {
    if (!this.desktopQuery.matches) {
      // 모바일은 페이지 진입 시 항상 닫힌 상태
      this.el.checked = false;
      return;
    }

    const savedState = localStorage.getItem(this.storageKey);

    // 데스크톱 최초 방문은 펼침 상태
    this.el.checked = savedState === null ? true : savedState === "true";
  },
};

export default SidebarState;
