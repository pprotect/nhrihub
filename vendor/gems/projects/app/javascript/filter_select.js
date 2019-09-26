export default Ractive.extend({
  computed: {
    selected: function() {
      return _(this.get(`filter_criteria.${this.get('collection')}`)).indexOf(this.get('id')) !== -1;
    }
  },
  toggle: function(id) {
    this.event.original.preventDefault();
    this.event.original.stopPropagation();
    if (this.get("selected")) {
      return this.unselect();
    } else {
      return this.select();
    }
  },
  select: function() {
    return this.push(`filter_criteria.${this.get('collection')}`, this.get('id'));
  },
  unselect: function() {
    return this.set(`filter_criteria.${this.get('collection')}`, _(this.get(`filter_criteria.${this.get('collection')}`)).without(this.get('id')));
  }
});

