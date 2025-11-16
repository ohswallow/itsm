const MaintainHeight = {
  beforeUpdate() {
    this.prevHeight = this.el.style.height;
  },

  updated() {
    this.el.style.height = this.prevHeight;
  },
};

export default MaintainHeight;
