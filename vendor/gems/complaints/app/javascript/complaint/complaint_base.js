var InpageEditDecorator = require("exports-loader?InpageEditDecorator!inpage_edit_decorator")
import EditBackup from 'edit_backup'
import AreasSelector from 'complaint/areas_selector'
import AgenciesSelector from 'agencies_select/agencies_selector'
import Area from 'area'
import Assignees from 'assignees'
import AssigneeSelector from 'assignee_selector'
import ComplaintDocuments from 'complaint/complaint_documents'
import ShowTimelineEvent from 'show_timeline_event.ractive.pug'
import SubareaSelector from 'complaint/subarea_selector.ractive.pug'
import Persistence from 'persistence'
import ConfirmDeleteModal from 'confirm_delete_modal'
import Remindable from 'remindable.coffee'
import Notable from 'notable.coffee'
import Communications from 'communications.ractive.pug'
var RactiveLocalMethods = require("exports-loader?local_methods!ractive_local_methods")
import translations from 'translations.js'
import Validator from 'validator'
import reminders from 'reminders.ractive.pug'
import notes from 'notes.ractive.pug'
import 'bootstrap'
import DupeList from 'dupe_list.ractive.pug'
import 'string.coffee'
import Buttons from 'buttons.ractive.pug'
import StatusChange from 'status_change.ractive.pug'
import TransfereeSelector from 'transferee_selector.ractive.pug'
import Transferees from 'transferees.ractive.pug'
import JurisdictionBranchSelector from 'jurisdiction_branch_selector.ractive.pug'
import Lifecycle from 'partials/_lifecycle.pug'
import Documents from 'partials/_documents.pug'
import _Agencies from 'partials/_agencies.pug'
import Areas from 'partials/_areas.pug'
import Subareas from 'partials/_subareas.pug'
import ComplainedToAgency from 'partials/_complained_to_agency.pug'
import DesiredOutcome from 'partials/_desired_outcome.pug'
import Details from 'partials/_details.pug'
import PreferredMeans from 'partials/_preferred_means.pug'
import Actions from 'partials/_actions.pug'
import Address from 'partials/_address.pug'
import ContactInfo from 'partials/_contact_info.pug'
import Legislations from 'partials/_legislations.pug'
import DateReceived from 'partials/_date_received.pug'
import Duplicates from 'partials/_duplicates.pug'
import LegislationSelector from 'legislation_selector.ractive.pug'
import Datepicker from 'datepicker'
import Duplicate from 'duplicate.ractive.pug'

export default Ractive.extend({
  el: '#complaint',
  computed : {
    province_name(){
      return _(this.get('provinces')).findWhere({id: this.get('province_id')}).name
    },
    //agency_ids(){
        //var ids = _(this.findAllComponents('agenciesSelector')).map(function(as){return as.get('agency_id')});
        //return _(ids).reject(function(i){return _.isNull(i)})
        //var ass = this.findAllComponents('agenciesSelector')
        //var ids = []
        //for(var i=0; i<ass.length; i++){
          //ids[i] = ass[i].get('agency_id')
        //}
        //return ids
    //},
    //agency_ids:{
      //get(){
        //var ids = _(this.findAllComponents('agenciesSelector')).map(function(as){return as.get('agency_id')});
        //return _(ids).reject(function(i){return _.isNull(i)})
      //},
      //set(val){
        //this.findComponent('agenciesSelector').set('agency_id', val);
      //}
    //},
    related_legislation_names(){
      if(!_.isEmpty(this.get('legislation_ids'))){
        var that = this
        var legislations = _(this.get('legislations')).
                             filter(function(l){return that.get('legislation_ids').indexOf(l.id) != -1})
        return _(legislations).map(function(l){return l.name})
      }else{
        return ['not configured']
      }
    },
    timeline_events_recent_first(){
      // on update, it seems that ractive  doesn't render in the order of the data object, so we need to force the correct sort
      return _(this.get('timeline_events')).sortBy(function(sc){return -$.datepicker.formatDate('@',new Date(sc.change_date)) });
    },
    regional_offices(){
      var group = _(this.get('office_groups')).findWhere({name: "Regional Offices"});
      return group.offices;
    },
    provincial_offices(){
      var group = _(this.get('office_groups')).findWhere({name: "Provincial Offices"});
      return group.offices;
    },
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
      var query = {match: {}};
      _(attrs).map(function(attr){query.match[attr]=that.get(attr)})
      return query
    }
  },
  partials: {
    lifecycle: Lifecycle,
    documents: Documents,
    agencies: _Agencies,
    areas: Areas,
    subareas: Subareas,
    complained_to_agency: ComplainedToAgency,
    desired_outcome: DesiredOutcome,
    details: Details,
    preferred_means: PreferredMeans,
    actions: Actions,
    address: Address,
    contact_info: ContactInfo,
    legislations: Legislations,
    date_received: DateReceived,
    duplicates: Duplicates,
  },
  oninit() {
    this.set({
      editing : false,
      serialization_key:'complaint',
      new_assignee_id: 0,
      new_transferee_id: 0,
      new_jurisdiction_branch_id: 0,
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
    agenciesSelector : AgenciesSelector,
    area : Area,
    assignees : Assignees,
    assigneeSelector : AssigneeSelector,
    attachedDocuments : ComplaintDocuments,
    showTimelineEvent : ShowTimelineEvent,
    subareaSelector: SubareaSelector,
    dupeList: DupeList,
    //progressBar : ProgressBar,
    buttons: Buttons,
    statusChange: StatusChange,
    transfereeSelector: TransfereeSelector,
    transferees: Transferees,
    jurisdictionBranchSelector: JurisdictionBranchSelector,
    legislationSelector: LegislationSelector,
    datepicker: Datepicker,
    duplicate: Duplicate,
  },
  add_agency(){
    this.push('agencies',{id: null})
  },
  remove_agency_id(id){
    this.set('agency_ids', _(this.get('agency_ids')).without(id))
  },
  add_agency_id(id){
    this.push('agency_ids',id)
    this.remove_attribute_error('agency_ids')
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
  query_has_values(query){
    var relevant_attributes = _(query.match).omit('type')
    var values = _.values(relevant_attributes)
    let emptyArray = val=> _.isArray(val) && val.map(l=>!_.isNumber(l)).every(l=>l) 
    return !values.every(val=>_.isEmpty(val) || emptyArray(val)) // null value or empty array
  },
  validate_query(query){
    var valid = this.query_has_values(query)
    this.set('invalid_query', !valid)
    return valid
  },
  check_dupes(){
    const query = this.get('duplication_query');
    if(this.validate_query(query)){
      return $.ajax({
        method : 'get',
        data: $.param(query),
        url : Routes.duplicate_complaints_path('en'),
        success : this.fetch_dupes_callback,
        context : this,
        processData : false,
        contentType : false
      });
    }
  },
  fetch_dupes_callback(response, status, jqxhr){
    this.set('agencyMatch', response.agency_match)
    this.set('complainantMatch', response.complainant_match)
    this.findComponent("dupeList").showModal()
  },
  async async_validate(){
    if(_.isEmpty(this.get('dupe_refs'))){
      return true
    }
    let result = await $.get(
      Routes.case_references_path('en'),
      {dupe_refs: this.get('dupe_refs')}
    )
    this.set('dupe_refs_not_found_error', !result.case_references_exist)
    return result.case_references_exist
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
