module.exports = {
  toggle() {
    this.event.original.preventDefault();
    this.event.original.stopPropagation();
    this.set('selected',!this.get('selected'));
    return complaints.load();
  },
  computed : {
    array_source : function(){return _.isArray(this.get(this.source))},
    selected : {
      get() {
        if(this.get('array_source')){
          return this.get(this.source).indexOf(this.get('name')) !== -1;
        }else{
          return this.get(this.source) === this.get('id');
        }
      },
      set(val){
        if (val) {
          if(this.get('array_source')){
            return this.push(this.source, this.get('name'));
          }else{
            return this.set(this.source,this.get('id'));
          }
        } else {
          if(this.get('array_source')){
            return this.remove_from_array(this.source, this.get('name'));
          }else{
            return this.set(this.source,null);
          }
        }
      }
    }
  }
};

