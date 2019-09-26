// mixin for ractive views
export default {
  remove_performance_indicator: function(indexed_description) {
    var index;
    index = this.performance_indicator_index(indexed_description);
    this.get('performance_indicator_associations').splice(index, 1);
    this.update('performance_indicator_associations'); // b/c splice no longer updates the model
    if (this.get('performance_indicator_required')) {
      return this.validate_attribute('performance_indicator_associations');
    }
  },
  performance_indicator_index: function(indexed_description) {
    return this.performance_indicator_ids().indexOf(indexed_description);
  },
  performance_indicator_ids: function() {
    return _(this.get('performance_indicator_associations')).map(function(pia) {
      return pia.performance_indicator.indexed_description;
    });
  },
  has_performance_indicator_id: function(performance_indicator_id) { // it's the id of the performance indicator, i.e. performance_indicator.id
    var ids;
    ids = _(this.get('performance_indicator_associations')).map(function(pia) {
      return pia.performance_indicator.id;
    });
    return ids.indexOf(performance_indicator_id) !== -1;
  },
  add_unique_performance_indicator_id: function(performance_indicator_id) {
    var performance_indicator_association;
    if (!this.has_performance_indicator_id(performance_indicator_id)) {
      performance_indicator_association = {
        id: null,
        association_id: this.get('id'), // no id for a new collectionItem
        performance_indicator_id: performance_indicator_id, // need this
        performance_indicator: {
          id: performance_indicator_id,
          indexed_description: this.get('performance_indicators')[performance_indicator_id]
        }
      };
      this.push('performance_indicator_associations', performance_indicator_association);
      return this.remove_attribute_error('performance_indicator_associations');
    }
  },
  remove_attribute_error: function(attribute) {
    return this.set(attribute + "_error", false);
  }
};
