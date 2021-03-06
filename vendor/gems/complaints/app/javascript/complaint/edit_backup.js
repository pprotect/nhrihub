export default {
  stash() {
    const stashable_attributes = this.get("persistent_attributes");
    const stashed_attributes = _(this.get()).pick(stashable_attributes);
    Object.assign(stashed_attributes, {attached_documents : this.get('attached_documents')});
    this.stashed_instance = $.extend(true,{},stashed_attributes);
    this.stashed_agencies = $.extend(true,{},this.get('agencies'));
  },
  restore() {
    this.set(this.stashed_instance);
    this.configure_agency_select_menu(this.stashed_agencies);
  },
  configure_agency_select_menu(agencies){
    // params, e.g. { "top_level_category": "municipalities", ... etc, "agency_id": 3823}
    // these params must be restored one-by-one in high-to-low order, vs in bulk
    // b/c lower order menus are set to default, when higher order menus are restored
    // and are then overwritten by this config
    var attrs = ["top_level_category", "selected_province_id", "national_agency_type", "selected_id", "agency_id", "selected_national_agency_id"]
    var selection_vectors = _(agencies).map(function(a){return a.selection_vector})
    for(var j=0; j<selection_vectors.length; j++){
      var params = selection_vectors[j]
      var config_attrs = Object.keys(params)
      for(var i=0; i<attrs.length; i++){
        var attr = attrs[i];
        if(config_attrs.indexOf(attr) != -1){
          this.set('agencies.'+j+'.selection_vector.'+attr,params[attr])
        }
      }
    }
  },
};

