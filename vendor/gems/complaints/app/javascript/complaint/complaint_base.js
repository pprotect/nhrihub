//import 'jquery-ui/ui/widgets/datepicker'
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
    persistent_attributes() {
      return ['id_type','id_value','alt_id_type','alt_id_value', 'alt_id_other_type',
        'city','province','postal_code','complaint_area_id',
        'physical_address', 'postal_address','home_phone','cell_phone','fax','preferred_means',
        'current_status_humanized', 'new_assignee_id', 'subarea_ids',
        'agency_ids', 'attached_documents_attributes', 'details',
        'dob', 'email', 'complained_to_subject_agency', 'desired_outcome', 'gender', 'date',
        'firstName', 'lastName', 'title', 'type'];
    },
    url() {
      if (this.get('persisted')) { return Routes.complaint_path(current_locale, this.get('id')); }
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
    subarea_id_count() { // aka subareas
      const sa = this.get('subarea_ids');
      const sal = _.isUndefined(sa) ? 0 : sa.length;
      return sal;
    },
    validation_criteria() {
      return {
        firstName : ['notBlank'],
        lastName : ['notBlank'],
        city : ['notBlank'],
        postal_code : ['notBlank'],
        province : ['notBlank'],
        complaint_area_id : 'numeric',
        subarea_id_count : 'nonZero',
        new_assignee_id: ['nonZero', {if : () => {return (this.get('new_complaint') && this.get('editing'))}}],
        dob: () => {
          const date_regex = new RegExp(/(\d{1,2})\/(\d{1,2})\/(\d{4})/); // dd/mm/yyyy
          const match = date_regex.exec(this.get('dob'));
          const valid_day = match && (parseInt(match[1]) <= 31);
          const valid_month = match && (parseInt(match[2]) <= 12);
          const valid_year = match && (parseInt(match[3]) <= (new Date).getFullYear()) && (parseInt(match[3]) >= 1900 );
          return !_.isNull(match) && valid_day && valid_month && valid_year;
        },
        details : ['notBlank'],
        preferred_means : 'notBlank',
        postal_address: ['notBlank', {if: ()=>this.get('preferred_means') == 'mail'}],
        email: ['notBlank', {if: ()=>this.get('preferred_means') == 'email'}],
        home_phone: ['notBlank', {if: ()=>this.get('preferred_means') == 'home_phone'}],
        cell_phone: ['notBlank', {if: ()=>this.get('preferred_means') == 'cell_phone'}],
        fax: ['notBlank', {if: ()=>this.get('preferred_means') == 'fax'}]
      };
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
  },
  data : function(){ return {
    t : translations.t('complaint')
  }},
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
    //progressBar : ProgressBar
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
