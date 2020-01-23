var EditInPlace = require("exports-loader?EditInPlace!edit_in_place")
import 'jquery-ui/ui/widgets/datepicker'
import EditBackup from 'edit_backup'
import AreasSelector from 'complaint/areas_selector'
import Agencies from 'agencies'
import AgenciesSelector from 'agencies_selector'
import Area from 'area'
import Assignees from 'assignees'
import AssigneeSelector from 'assignee_selector'
import ComplaintDocuments from 'complaint/complaint_documents'
import StatusChange from 'status_change.ractive.pug'
import SubareaSelector from 'complaint/subarea_selector.ractive.pug'
import Persistence from 'persistence'
import ConfirmDeleteModal from 'confirm_delete_modal'
import Remindable from 'remindable.coffee'
import Notable from 'notable.coffee'
import Communications from 'communications.ractive.pug'
var RactiveLocalMethods = require("exports-loader?local_methods!ractive_local_methods")
import translations from 'translations.js'
import Validator from 'validator'
var SingleMonthDatepicker = require("exports-loader?SingleMonthDatepicker!single_month_datepicker.coffee")
Ractive.decorators.single_month_datepicker = SingleMonthDatepicker
import reminders from 'reminders.ractive.pug'
import notes from 'notes.ractive.pug'
import 'bootstrap'
import DupeList from 'dupe_list.ractive.pug'
import 'string.coffee'
import Buttons from 'buttons.ractive.pug'

export default Ractive.extend({
  el: '#complaint',
  computed : {
    delete_confirmation_message() {
      return `${i18n.delete_complaint_confirmation_message} ${this.get('case_reference')}?`;
    },
    reminders_count() {
      const reminders = this.get('reminders');
      if (_.isUndefined(reminders)) { return 0; } else { return reminders.length; }
    },
    notes_count() {
      const notes = this.get('notes');
      if (_.isUndefined(notes)) { return 0; } else { return notes.length; }
    },
    communications_count() {
      const comms = this.get('communications');
      if (_.isUndefined(comms)) { return 0; } else { return comms.length; }
    },
    persisted() {
      return !(_.isNull(this.get('id')) || _.isUndefined(this.get('id')));
    },
    url() {
      if (this.get('persisted')) {
        return Routes.complaint_path(current_locale, this.get('id'));
      }else{
        return Routes.complaint_register_path(current_locale, type)
      }
    },
    formatted_date : {
      get() {
        const date_received = this.get('date'); // it's a formatted version of date_received
        if (_.isEmpty(date_received)) {
          return "";
        } else {
          return this.get('date');
        }
      },
      set(val){
        return this.set('date', val);
      }
    },
    has_errors() {
      return this.validator.has_errors();
    },
    complaint_area_name() {
      if(_.isNull(this.get('complaint_area_id'))){return null}
      const complaint_area = _(this.get('all_complaint_areas')).find(complaint_area=>complaint_area.id==this.get('complaint_area_id'))
      return complaint_area.name;
    },
    create_reminder_url() {
      if (this.get('persisted')) { return Routes.complaint_reminders_path('en', this.get('id')); }
    },
    create_note_url() {
      if (this.get('persisted')) { return Routes.complaint_notes_path('en', this.get('id')); }
    },
    subarea_id_count() {
      const sa = this.get('subarea_ids');
      const sal = _.isUndefined(sa) ? 0 : sa.length;
      return sal;
    },
    error_vector() {
      return {
        firstName_error : this.get('firstName_error'),
        lastName_error : this.get('lastName_error'),
        city_error : this.get('city_error'),
        new_assignee_id_error : this.get('new_assignee_id_error'),
        complaint_area_id_error : this.get('complaint_area_id_error'),
        subarea_id_count_error : this.get('subarea_id_count_error'),
        dob_error : this.get('dob_error'),
        details_error : this.get('details_error')
      };
    },
    new_complaint(){
      return _.isNull(this.get('id'))
    },
    intake(){
      return this.get('mode')=='intake';
    },
    register(){
      return !this.get('intake');
    },
    update_complaint(){
      return !this.get('new_complaint')
    },
    other_id_selected() {
      return this.get('alt_id_type') == 'other';
    },
    alt_id_name(){
      if(this.get('other_id_selected')){
        return this.get('alt_id_other_type')
      }else{
        return this.get('alt_id_type')
      }
    },
    duplication_query(){
      var attrs = this.get('dupe_check_attributes');
      var that = this;
      var query = {};
      _(attrs).map(function(attr){query["match["+attr+"]"]=that.get(attr)})
      return query
    }
  },
  oninit() {
    this.set({
      editing : false,
      serialization_key:'complaint',
      new_assignee_id: 0,
    });
  },
  onconfig() {
    return this.validator = new Validator(this);
  },
  oncomplete(){ 
    if(this.get('new_complaint')){ this.editor.edit_start($('.editable_container')) }
    if(this.get('intake')){ this.disable_non_dupe_check_inputs(); }
  },
  data : function(){
    return {
      t : translations.t('complaint'),
      register_heading : translations.t('complaint.register_heading',{type: type.humanize().titlecase()})
    }
  },
  components : {
    areasSelector : AreasSelector,
    agencies : Agencies,
    agenciesSelector : AgenciesSelector,
    area : Area,
    assignees : Assignees,
    assigneeSelector : AssigneeSelector,
    attachedDocuments : ComplaintDocuments,
    statusChange : StatusChange,
    subareaSelector: SubareaSelector,
    dupeList: DupeList,
    //progressBar : ProgressBar,
    buttons: Buttons
  },
  partials : {
    buttons : Buttons
  },
  proceed_to_intake(){
    history.pushState({},"anything",this.get('url'));
    this.enable_all_inputs();
    complaint.set({heading:this.get('register_heading'),
                   mode:'register'});
  },
  enable_all_inputs(){
    $(this.el).find('input, select').attr('disabled',false)
    $(this.el).find('.fileinput-button').attr('disabled',false)
  },
  disable_non_dupe_check_inputs(){
    $(this.el).find('input:not(.dupe_check), select:not(.dupe_check)').attr('disabled',true)
    $(this.el).find('.fileinput-button').attr('disabled',true)
  },
  check_dupes(){
    const data = $.param(this.get('duplication_query'));
    return $.ajax({
      method : 'get',
      data,
      url : Routes.duplicate_complaints_path('en'),
      success : this.fetch_dupes_callback,
      context : this,
      processData : false,
      contentType : false
    });
  },
  fetch_dupes_callback(response, status, jqxhr){
    this.set('agencyMatch', response.agency_match)
    this.set('complainantMatch', response.complainant_match)
    this.findComponent("dupeList").showModal()
  },
  generate_word_doc() {
    return window.location = Routes.complaint_path('en',this.get('id'),{format : 'docx'});
  },
  validate() {
    return this.validator.validate();
  },
  validate_attribute(attribute){
    return this.validator.validate_attribute(attribute);
  },
  remove_attribute_error(attribute){
    var that = this
    _(arguments).each(function(attribute){
      that.set(attribute+"_error",false);
    })
  },
  remove_errors() {
    return this.restore();
  },
  cancel_add_complaint() {
    UserInput.reset();
    return this.parent.shift('complaints');
  },
  remove(guid){
    // required for Ractive 0.8.0, possibly can be removed in later revs
    const guids = _(this.findAllComponents('attachedDocument')).pluck('_guid');
    const index = _(guids).indexOf(guid);
    return this.splice('attached_documents',index,1);
  },
  add_file(file){
    const attached_document = {
      id : null,
      complaint_id : this.get('id'),
      file,
      title: '',
      file_id : '',
      url : '',
      original_filename : file.name,
      filesize : file.size,
      original_type : file.type,
      serialization_key : 'complaint[complaint_documents_attributes][]'
    };
    return this.unshift('attached_documents', attached_document);
  }}).extend(EditBackup)
  .extend(Persistence)
  .extend(ConfirmDeleteModal)
  .extend(Remindable)
  .extend(Notable)
  .extend(Communications)
  .extend(RactiveLocalMethods);
