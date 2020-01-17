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
  office_groups : source_office_groups,
  branches : source_branches,
  i18n: window.i18n
})

import IndividualComplaint from '../individual_complaint.ractive.pug'
import OrganizationComplaint from '../organization_complaint.ractive.pug'
import OwnMotionComplaint from '../own_motion_complaint.ractive.pug'
window.start_page = function(){
  if(type == "individual"){
    window.complaint = new IndividualComplaint({data: complaint_data}) }
  else if(type == "organization"){
    window.complaint = new OrganizationComplaint({data: complaint_data}) }
  else if(type == "own_motion"){
    window.complaint = new OwnMotionComplaint({data: complaint_data}) }
  complaint.set({heading: i18n.heading, type: type});
}

window.onpopstate = function(event) {
  window.start_page();
  complaint.set(event.state.content);
};

$(function() {
  start_page();
  // capture complaint data for current url
  history.replaceState({content: complaint_data, page: mode},"whatever",window.location.pathname)
});

