require("@rails/ujs").start()

_.extend(Ractive.defaults.data, {
  all_agencies : source_all_agencies,
  all_subareas : source_subareas,
  fade: window.env!='test',
  all_users : source_all_users,
  all_complaint_areas : source_areas,
  complaint_bases : source_complaint_bases,
  all_agencies : source_all_agencies,
  all_agencies_in_sixes : _.chain(source_all_agencies).groupBy(function(el,i){return Math.floor(i/6)}).toArray().value(),
  all_staff : source_all_staff,
  permitted_filetypes : source_permitted_filetypes,
  maximum_filesize : source_maximum_filesize,
  communication_permitted_filetypes : source_communication_permitted_filetypes,
  communication_maximum_filesize : source_communication_maximum_filesize,
  statuses : source_statuses,
  local : function(gmt_date){ return $.datepicker.formatDate("M d, yy", new Date(gmt_date)); }
})

import Complaint from '../new_complaint.ractive.pug'
window.start_page = function(){
  $('h1').html(title)
  window.complaint = new Complaint
}

window.onpopstate = function(event) {
  console.log("location: " + document.location + ", state: " + event.state.page);
  if(event.state.page == "new_individual_complaint")
  { window.start_page() }
  else if(event.state.page == "save_complaint_callback")
  {
    window.complaint.unrender()
    $('.container').html(event.state.content)
  }
};

$(function() {
  start_page();
  // so that a state object is present when returnng to the initial state with the back button
  // this is so we can discriminate returning to the page from page load
  complaint.set('type',type)
  history.replaceState({content: "could be anything", page: "new_individual_complaint"},"whatever","/en/complaints/new/individual")
});
