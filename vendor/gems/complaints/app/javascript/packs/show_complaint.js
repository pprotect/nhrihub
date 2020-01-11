require("@rails/ujs").start()

_.extend(Ractive.defaults.data, {
  all_subareas : source_subareas,
  all_users : source_all_users,
  all_complaint_areas : source_areas,
  all_agencies : source_all_agencies,
  all_agencies_in_sixes : _.chain(source_all_agencies).groupBy(function(el,i){return Math.floor(i/6)}).toArray().value(),
  all_staff : source_all_staff,
  permitted_filetypes : source_permitted_filetypes,
  maximum_filesize : source_maximum_filesize,
  communication_permitted_filetypes : source_communication_permitted_filetypes,
  communication_maximum_filesize : source_communication_maximum_filesize,
  statuses : source_statuses,
  i18n: window.i18n
})

import Complaint from '../show_complaint.ractive.pug'
window.start_page = function(){
  window.complaint = new Complaint({data: complaint_data})
}

window.onpopstate = function(event) {
  window.start_page();
  complaint.set(event.state.content);
};

$(function() {
  start_page();
  complaint.set({heading: i18n.heading, type: type});
  // capture complaint data for current url
  history.replaceState({content: complaint_data, page: mode},"whatever",window.location.pathname)
});

