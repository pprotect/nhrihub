/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb


import project_options from '../projects.ractive.pug'
import FileInput from '../../../../../../app/assets/javascripts/file_input_decorator.js'
import EditInPlace from '../project/edit_in_place.js'
import notes from  'notes.ractive.pug'
import remindables from 'reminders.ractive.pug'
import '../../../../../../app/assets/javascripts/ractive_local_methods.coffee'

window.notes = notes
window.reminders = reminders

require("@rails/ujs").start()

Ractive.decorators.ractive_fileupload = FileInput;
Ractive.decorators.inpage_edit = EditInPlace;


var performance_indicators = _.chain(planned_results).
  map(function(pr){return pr.outcomes}).
  flatten().
  map(function(pr){return pr.activities}).
  flatten().
  map(function(a){return a.performance_indicators}).
  flatten().
  map(function(a){return _(a).values()}).
  object().
  value()

_.extend(Ractive.defaults.data, {
  all_mandates : all_mandates,
  planned_results : planned_results,
  areas : areas,
  subareas : subareas,
  performance_indicators : performance_indicators,
  performance_indicator_url : performance_indicator_url,
  maximum_filesize : maximum_filesize,
  permitted_filetypes : permitted_filetypes,
  all_users : all_users,
  default_filter_criteria : default_filter_criteria
})


window.start_page = function(){
  window.projects = new Ractive(project_options)
}

$(function(){
  start_page()
  // so that a state object is present when returnng to the initial state with the back button
  // this is so we can discriminate returning to the page from page load
  history.replaceState({bish:"bosh"},"bash",window.location)
})

window.onpopstate = function(event) {
  if (event.state) { // to ensure that it doesn't trigger on page load, it's a problem with phantomjs but not with chrome
    return window.projects.findComponent('filterControls').set_filter_from_query_string();
  }
};
