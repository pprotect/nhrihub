//= require 'confirm_delete_modal'
//= require 'performance_indicator'
//= require 'fade'
//= require 'slide'
//= require 'in_page_edit'
//= require 'ractive_local_methods'
//= require 'string'
//= require 'validator'
//= require 'file_input_decorator'
//= require 'progress_bar'
//= require 'jquery_datepicker'
//= require 'filter_criteria_datepicker'
//= require 'confirm_delete_modal'
//= require 'remindable'
//= require 'notable'

Ractive.DEBUG = false

Ractive.defaults.data =
  performance_indicator_url : Routes.project_performance_indicator_path(current_locale,'id')
  all_mandates : all_mandates
  subareas : subareas
  planned_results : planned_results
  all_areas : areas
  areas : areas 
  agencies : agencies
  all_agencies_in_threes : all_agencies_in_threes
  project_named_documents_titles : project_named_documents_titles
  permitted_filetypes : permitted_filetypes
  maximum_filesize : maximum_filesize
  performance_indicators : performance_indicators

AreaSelector = Ractive.extend
  template : '#area_selector_template'

SubareasSelector = Ractive.extend
  template : '#subareas_selector_template'

Subarea = Ractive.extend
  template : '#subarea_template'
  computed :
    name : ->
      _(@get('subareas')).findWhere({id : @get('id')}).name unless @get('id') == 0

Area = Ractive.extend
  template : '#area_template'
  computed :
    name : ->
      _(@get('areas')).findWhere({id : @get('area_id')}).name unless @get('area_id') == 0
  components :
    subarea : Subarea

EditBackup =
  stash : ->
    stashed_attributes = _(@get()).omit('performance_indicator_ids', 'expanded', 'editing', 'performance_indicator_required', 'persistent_attributes', 'url', 'truncated_title', 'delete_confirmation_message', 'reminders_count', 'notes_count', 'count', 'persisted', 'type', 'include', 'create_note_url', 'create_reminder_url', 'has_errors', 'validation_criteria')
    @stashed_instance = $.extend(true,{},stashed_attributes)
  restore : ->
    #@restore_checkboxes()
    @set(@stashed_instance)
  #restore_checkboxes : ->
    ## major hack to circumvent ractive bug,
    ## it will not be necessary in ractive 0.8.0
    #_(['area','project_type']).
      #each (association)=>
        #@restore_checkboxes_for(association)
  #restore_checkboxes_for : (association)->
    #ids = @get("#{association}_ids")
    #_(@findAll(".edit .#{association} input")).each (checkbox)->
      #is_checked = ids.indexOf(parseInt($(checkbox).attr('value'))) != -1
      #$(checkbox).prop('checked',is_checked)

ProjectDocumentValidator = _.extend
  initialize_validator: ->
    @set 'validation_criteria',
      'file.size' :
        ['lessThan', @get('maximum_filesize')]
      'file.type' :
        ['match', @get('permitted_filetypes')]
    @set('unconfigured_validation_parameter_error',false)
  , Validator

ProjectDocument = Ractive.extend
  template : "#project_document_template"
  oninit : ->
    if !@get('persisted')
      @initialize_validator()
      @validate()
  data :
    serialization_key : 'project[project_documents_attributes][]'
  computed :
    persistent_attributes : ->
      ['title', 'original_filename', 'file', 'original_type'] unless @get('id') # only persist if it's not already persisted, otherwise don't
    unconfigured_filetypes_error : ->
      @get('unconfigured_validation_parameter_error')
    persisted : ->
      !_.isNull(@get('id'))
    url : ->
      Routes.project_document_path(current_locale, @get('id')) unless _.isNull(@get('id'))
    truncated_title : ->
      @get('title').split(' ').slice(0,4).join(' ')+"..."
    truncated_title_or_filename : ->
      unless _.isEmpty(@get('title'))
        @get('truncated_title')
      else
        @get('original_filename')
    delete_confirmation_message : ->
      "#{delete_project_document_confirmation_message} \"#{@get('truncated_title_or_filename')}\"?"
  remove_file : ->
    @parent.remove(@_guid)
  delete_callback : (data,textStatus,jqxhr)->
    @parent.remove(@_guid)
  download_attachment : ->
    window.location = @get('url')
.extend ProjectDocumentValidator
.extend ConfirmDeleteModal

ProjectDocuments = Ractive.extend
  template : "#project_documents_template"
  components :
    projectDocument : ProjectDocument
  remove : (guid)->
    guids = _(@findAllComponents('projectDocument')).pluck('_guid')
    index = _(guids).indexOf(guid)
    @splice('project_documents',index,1)

Persistence = $.extend
  delete_callback : (data,textStatus,jqxhr)->
    @parent.remove(@_guid)
  formData : ->
    @asFormData @get('persistent_attributes') # in ractive_local_methods, returns a FormData instance
  update_persist : (success, error, context) -> # called by EditInPlace
    if @validate()
      data = @formData()
      $.ajax
        # thanks to http://stackoverflow.com/a/22987941/451893
        #xhr: @progress_bar_create.bind(@)
        method : 'put'
        data : data
        url : Routes.project_path(current_locale, @get('id'))
        #success : @update_project_callback
        success : success
        #context : @
        context : context
        processData : false
        contentType : false # jQuery correctly sets the contentType and boundary values
  #update_project_callback : (response, statusText, jqxhr)->
     #@editor.show() # before updating b/c we'll lose the handle
     #@set(response)
  save_project: ->
    if @validate()
      data = @formData()
      $.ajax
        # thanks to http://stackoverflow.com/a/22987941/451893
        #xhr: @progress_bar_create.bind(@)
        method : 'post'
        data : data
        url : Routes.projects_path(current_locale)
        success : @save_project_callback
        context : @
        processData : false
        contentType : false # jQuery correctly sets the contentType and boundary values
  save_project_callback : (response, status, jqxhr)->
    UserInput.reset()
    @set(response)
  progress_bar_create : ->
    @findComponent('progressBar').start()
  , ConfirmDeleteModal

FilterMatch =
  include : ->
    @matches_title() &&
    @matches_area() &&
    @matches_subarea() &&
    @matches_performance_indicator()
  matches_title : ->
    escaped_title = @get('filter_criteria.title').
                      replace(/\\/g,"\\\\").
                      replace(/(\?|\(|\)|\[|\]|\{|\}|\.|\>|\<)/g,"\\$1")
    re = new RegExp(escaped_title.trim(),"i")
    re.test @get('title')
  matches_area : ->
    criterion = @get('filter_criteria.area_ids')
    value = @get('mandate_id')
    select_undesignated = _(criterion).include(0) # 0 means undesignated area
    undesignated = _.isNull(value) || _.isUndefined(value)
    match_undesignated = select_undesignated && undesignated
    match_value = _(criterion).include(value)
    match_value || match_undesignated
  matches_subarea : ->
    criterion = @get('filter_criteria.subarea_ids')
    value = @get('subarea_ids')
    select_undesignated = _(criterion).include(0) # 0 means undesignated subarea
    undesignated = _.isEmpty(value)
    match_undesignated = select_undesignated && undesignated
    @contains(criterion,value) || match_undesignated
  matches_performance_indicator : ->
    criterion = parseInt(@get('filter_criteria.performance_indicator_id'))
    values = @get('performance_indicator_ids')
    return true if _.isUndefined(criterion) || _.isNaN(criterion)
    _(values).indexOf(criterion) != -1
  contains : ( criterion, value) ->
    #return true if _.isEmpty(criterion)
    common_elements = _.intersection(criterion, value)
    # must have some common elements
    !_.isEmpty(common_elements)

Project = Ractive.extend
  template : '#project_template'
  oninit : ->
    @set
      'editing' : false
      'title_error': false
      'description_error': false
      'performance_indicator_associations_error': false
      'project_error':false
      'filetype_error': false
      'filesize_error': false
      'expanded':false
      'serialization_key':'project'
  computed :
    performance_indicator_required : -> true
    performance_indicator_ids : ->
      _(@get('performance_indicator_associations')).map (pia)->pia.performance_indicator.id
    persistent_attributes : ->
      # the asFormData method knows how to interpret 'project_documents_attributes'
      ['title', 'description', 'mandate_id', 'subarea_ids',
       'selected_performance_indicators_attributes', 'project_documents_attributes']
    url : ->
      Routes.project_path(current_locale,@get('id'))
    truncated_title : ->
      @get('title').split(' ').slice(0,4).join(' ')+"..."
    delete_confirmation_message : ->
      "#{delete_project_confirmation_message} \"#{@get('truncated_title')}\"?"
    reminders_count : ->
      @get('reminders').length
    notes_count : ->
      @get('notes').length
    count : ->
      t = @get('title') || ""
      100 - t.length
    persisted : ->
      !_.isNull(@get('id'))
    type : ->
      window.model_name
    include : ->
      @include()
    create_note_url : ->
      window.create_note_url.replace('id',@get('id'))
    create_reminder_url : ->
      window.create_reminder_url.replace('id',@get('id'))
    has_errors : ->
      attributes = _(@get('validation_criteria')).keys()
      error_attributes = _(attributes).map (attr)->attr+"_error"
      _(error_attributes).any (attr)=>@get(attr)
    validation_criteria : ->
      title : 'notBlank'
      description : 'notBlank'
      performance_indicator_associations : ['nonEmpty', @get('performance_indicator_associations')]
    mandate_name :
      get: ->
        return null if _.isNull(@get('mandate_id'))
        mandate = _(@get('all_mandates')).findWhere({id : @get('mandate_id')})
        mandate.name
      set: (val)->
        return 'foo'
  components :
    areaSelector : AreaSelector
    subareasSelector : SubareasSelector
    area : Area
    subarea : Subarea
    projectDocuments : ProjectDocuments
    progressBar : ProgressBar
  cancel_project : ->
    UserInput.reset()
    @parent.remove(@_guid)
  expand : ->
    @set('expanded',true)
    $(@find('.collapse')).collapse('show')
  compact : ->
    @set('expanded',false)
    $(@find('.collapse')).collapse('hide')
  remove_errors : ->
    @compact() #nothing to do with errors, but this method is called on edit_cancel
    @restore()
  remove_attribute_error : (attr)->
    @set(attr+"_error", false)
  add_file : (file)->
    project =
      id : null
      project_id : @get('id')
      file : file
      title: ''
      file_id : ''
      url : ''
      original_filename : file.name
      original_type : file.type
    @unshift('project_documents', project)
  show_file_selector : ->
    @find('#project_fileinput').click()
.extend Validator
.extend PerformanceIndicatorAssociation
.extend EditBackup
.extend Persistence
.extend FilterMatch
.extend Remindable
.extend Notable

FilterSelect = Ractive.extend
  computed :
    selected : ->
      _(@get("filter_criteria.#{@get('collection')}")).indexOf(@get('id')) != -1
  toggle : (id)->
    @event.original.preventDefault()
    @event.original.stopPropagation()
    if @get("selected")
      @unselect()
    else
      @select()
  select : ->
    @push("filter_criteria.#{@get('collection')}",@get('id'))
  unselect : ->
    @set("filter_criteria.#{@get('collection')}", _(@get("filter_criteria.#{@get('collection')}")).without(@get('id')))

AreaFilterSelect = FilterSelect.extend
  template : "#area_filter_select_template"
  computed :
    collection : ->
      "area_ids"

UndesignatedAreaFilterSelect = AreaFilterSelect.extend({})

SubareaFilterSelect = FilterSelect.extend
  template : "#subarea_filter_select_template"
  computed :
    collection : ->
      "subarea_ids"

UndesignatedSubareaFilterSelect = SubareaFilterSelect.extend({
  css: ".subarea_filter{padding-left: 19px; padding-top:8px;}"
})

PerformanceIndicatorFilterSelect = Ractive.extend
  template: "#performance_indicator_filter_select_template"
  select : (id)->
    if @get('filter_criteria.performance_indicator_id') == id
      @set('filter_criteria.performance_indicator_id',null)
    else
      @set('filter_criteria.performance_indicator_id',id)

SelectClear = Ractive.extend
  template : "#select_clear_template"
  clear_all: ->
    event.stopPropagation()
    @parent.clear_all(@get('collection'))
  select_all: ->
    event.stopPropagation()
    @parent.select_all(@get('collection'))

FilterControls = Ractive.extend
  template : "#filter_controls_template"
  components :
    undesignatedSubareaFilterSelect : UndesignatedSubareaFilterSelect 
    undesignatedAreaFilterSelect : UndesignatedAreaFilterSelect
    areaFilterSelect : AreaFilterSelect
    subareaFilterSelect : SubareaFilterSelect
    selectClear : SelectClear
    performanceIndicatorFilterSelect : PerformanceIndicatorFilterSelect
  select_all : (collection)->
    subarea_ids = _(subareas).map (s)-> s.id
    subarea_ids.push(0) # the 'undesignated' subarea
    @set('filter_criteria.'+collection, subarea_ids)
  clear_all : (collection)->
    @set('filter_criteria.'+collection, [])
  expand : ->
    @parent.expand()
  compact : ->
    @parent.compact()
  clear_filter : ->
    window.history.pushState({foo: "bar"},"unused title string",window.location.origin + window.location.pathname)
    @set('filter_criteria', _.extend(window.projects_page_data().filter_criteria, {title : ""}))
  set_filter_from_query_string : ->
    search_string = if (_.isEmpty( window.location.search) || _.isNull( window.location.search)) then '' else window.location.search.split("=")[1].replace(/\+/g,' ')
    filter_criteria = _.extend(window.filter_criteria,{title : unescape(search_string)})
    @set('filter_criteria',filter_criteria)

window.projects_page_data = ->
  expanded : false
  projects : projects_data
  filter_criteria : filter_criteria

projects_options = ->
  el : "#projects"
  template : '#projects_template'
  data : $.extend(true,{},projects_page_data())
  components :
    project : Project
    filterControls : FilterControls
  new_project : ->
    unless @add_project_active()
      new_project_attributes =
        id : null
        title : ""
        description : ""
        mandate_id : null
        project_type_ids : []
        performance_indicator_associations : []
        project_documents : []
      UserInput.claim_user_input_request(@,'cancel_add_project')
      @unshift('projects', new_project_attributes)
  add_project_active : ->
    !_.isEmpty(@findAllComponents('project')) && !@findAllComponents('project')[0].get('persisted')
  cancel_add_project : ->
    new_project = _(@findAllComponents('project')).find (project)-> !project.get('persisted')
    @remove(new_project._guid)
  remove : (guid)->
    project_guids = _(@findAllComponents('project')).map (pr)-> pr._guid
    index = project_guids.indexOf(guid)
    @splice('projects',index,1)
  expand : ->
    @set('expanded',true)
    _(@findAllComponents('project')).each (project)->
      project.expand()
  compact : ->
    @set('expanded',false)
    _(@findAllComponents('project')).each (project)->
      project.compact()

EditInPlace = (node,id)->
  ractive = @
  edit = new InpageEdit
    object : @
    on : node
    focus_element : 'input.title'
    #success : (response, statusText, jqxhr)->
       #ractive = @.options.object
       #@.show() # before updating b/c we'll lose the handle
       #ractive.set(response)
    success : (response, textStatus, jqXhr)->
      @.options.object.set(response)
      @load()
    error : ->
      console.log "Changes were not saved, for some reason"
    start_callback : -> ractive.expand()
  return {
    teardown : (id)=>
      edit.off()
    update : (id)=>
    }

Ractive.decorators.inpage_edit = EditInPlace

window.start_page = ->
  window.projects = new Ractive projects_options()

$ ->
  start_page()
  # so that a state object is present when returnng to the initial state with the back button
  # this is so we can discriminate returning to the page from page load
  history.replaceState({bish:"bosh"},"bash",window.location)

window.onpopstate = (event)->
  if event.state # to ensure that it doesn't trigger on page load, it's a problem with phantomjs but not with chrome
    window.projects.findComponent('filterControls').set_filter_from_query_string()




