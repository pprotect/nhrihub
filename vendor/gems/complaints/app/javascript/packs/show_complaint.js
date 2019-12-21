require("@rails/ujs").start()

_.extend(Ractive.defaults.data, {
  //all_agencies : source_all_agencies,
  all_subareas : source_subareas,
  //fade: window.env!='test',
  //all_users : source_all_users,
  ////all_mandates : source_all_mandates,
  all_complaint_areas : source_areas,
  ////subareas : source_subareas,
  //complaint_bases : source_complaint_bases,
  all_agencies : source_all_agencies,
  all_agencies_in_sixes : _.chain(source_all_agencies).groupBy(function(el,i){return Math.floor(i/6)}).toArray().value(),
  all_staff : source_all_staff,
  //permitted_filetypes : source_permitted_filetypes,
  //maximum_filesize : source_maximum_filesize,
  //communication_permitted_filetypes : source_communication_permitted_filetypes,
  //communication_maximum_filesize : source_communication_maximum_filesize,
  //statuses : source_statuses,
  //local : function(gmt_date){ return $.datepicker.formatDate("M d, yy", new Date(gmt_date)); }
  i18n: window.i18n
})

import Complaint from '../show_complaint.ractive.pug'
window.start_page = function(){
  window.complaint = new Complaint({data: complaint_data})
}

$(function() {
  start_page();
});

