import Sortable from "../../vendor/sortable";

const SortableInputsFor = {
  mounted() {
    new Sortable(this.el, {
      animation: 150,
      ghostClass: "opacity-50",
      handle: ".hero-bars-3",
    });
  },
};

export default SortableInputsFor;
