/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb

window.urlQueryParams =function(){
  var query_string = window.location.search.substr(1);
  var query_string_fragments = query_string.split('&');
  var params = {}
  var extract_param=function(el){
    var array_type = el.match(/(\w*)%5B%5D=(\d*)/);
    var const_type = el.match(/(\w*)=(.*)/);
    if(array_type){
      var name = array_type[1];
      var val = parseInt(array_type[2]);
      if(params[name]){params[name][params[name].length] = val}else{params[name]=[val];}
    }else{
      var name = const_type[1];
      var val = const_type[2];
      params[name] = val;
    }
  };
  query_string_fragments.forEach(extract_param)
  return params;
};

window.complaints_page_data = function(){
  return {
    complaints : source_complaints_data,
    default_filter_criteria: source_filter_criteria,
    filter_criteria: urlQueryParams(),
    all_agencies : source_all_agencies,
    all_subareas : source_subareas,
  }
};

import complaints_options from '../complaints.ractive.pug'
var filter_criteria_datepicker = require("exports-loader?filter_criteria_datepicker!filter_criteria_datepicker")

require("@rails/ujs").start()

_.extend(Ractive.defaults.data, {
  fade: window.env!='test',
  all_users : source_all_users,
  areas : source_areas,
  subareas : source_subareas,
  all_agencies : source_all_agencies,
  all_office_groups : source_office_groups,
  permitted_filetypes : source_permitted_filetypes,
  maximum_filesize : source_maximum_filesize,
  communication_permitted_filetypes : source_communication_permitted_filetypes,
  communication_maximum_filesize : source_communication_maximum_filesize,
  statuses : source_statuses,
  local : function(gmt_date){ return $.datepicker.formatDate("M d, yy", new Date(gmt_date)); },
  i18n: i18n
})

window.start_page = function(){ window.complaints_page = new Ractive(complaints_options) }
window.page_ready = false;

$(function() {
  start_page();
  filter_criteria_datepicker.start(complaints_page);
  // so that a state object is present when returnng to the initial state with the back button
  // this is so we can discriminate returning to the page from page load
  //return history.replaceState({filter_criteria:complaints_page.get('filter_criteria')},"bash",window.location);
});

window.onpopstate = function(event){
  if (event.state) { // to ensure that it doesn't trigger on page load, it's a problem with phantomjs but not with chrome
    return window.complaints_page.set('filter_criteria',event.state.filter_criteria)
  }
};
