module.exports = {
  toggle() {
    this.event.original.preventDefault();
    this.event.original.stopPropagation();
    this.set('selected',!this.get('selected'));
  },
  computed : {
    // array source is like checkboxes, multiple selections possible
    // not_array_source is like radio boxes, single selection
    array_source : function(){return _.isArray(this.get(this.source))},
    selected : {
      get() {
        if(this.get('array_source')){
          return this.get(this.source).indexOf(this.get('id')) !== -1;
        }else{
          return this.get(this.source) == this.get('id');
        }
      },
      set(val){
        if (val) {
          if(this.get('array_source')){
            return this.push(this.source, this.get('id'));
          }else{
            return this.set(this.source,this.get('id'));
          }
        } else {
          if(this.get('array_source')){
            return this.remove_from_array(this.source, this.get('id'));
          }else{
            return this.set(this.source,null);
          }
        }
      }
    }
  }
};

