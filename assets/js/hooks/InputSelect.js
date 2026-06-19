const InputSelect = {};

InputSelect.selectAll = {
    mounted() {
        const allList = ["", "All", null, undefined];
        this.lastSelected = Array.from(this.el.selectedOptions).map(o => o.value);
        this.el.addEventListener("change", (e) => {
            const options = Array.from(this.el.options);
            const currentSelected = Array.from(this.el.selectedOptions).map(o => o.value);
            const hasAll = currentSelected.some(val => allList.includes(val));
            const previouslyHadAll = this.lastSelected.some(val => allList.includes(val));
            let finalSelection = currentSelected;
            if ((currentSelected.length === 0) || (hasAll && !previouslyHadAll)) {
                finalSelection = [""];
            } else if (hasAll && previouslyHadAll && currentSelected.length > 1) {
                finalSelection = currentSelected.filter(val => !allList.includes(val));
            }
            options.forEach(opt => {opt.selected = finalSelection.includes(opt.value);});

            this.lastSelected = finalSelection;
            this.el.dispatchEvent(new Event("input", { bubbles: true }));
        });
    }
}

export default InputSelect;
