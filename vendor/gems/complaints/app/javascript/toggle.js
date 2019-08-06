module.exports = {
  oninit() {
    return this.set('selected',false);
  },
  toggle() {
    this.event.original.preventDefault();
    this.event.original.stopPropagation();
    return this.set('selected',!this.get('selected'));
  },
  computed : {
    selected : {
      get() {
        return this.get(this.source).indexOf(this.get('name')) !== -1;
      },
      set(val){
        if (val) {
          return this.push(this.source, this.get('name'));
        } else {
          return this.remove_from_array(this.source, this.get('name'));
        }
      }
    }
  }
};

