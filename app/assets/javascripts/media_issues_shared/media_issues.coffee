#= require 'string'
#= require 'ractive_validator'
#= require 'ractive_local_methods'
#= require 'performance_indicator'
#= require 'remindable'
#= require 'notable'
#= require 'confirm_delete_modal'
#= require 'filter_criteria_datepicker'

$ ->
  Collection.EditInPlace = (node,id)->
    ractive = @
    @edit = new InpageEdit
      on : node
      object : @
      focus_element : 'input.title'
      success : (response, textStatus, jqXhr)->
        @.options.object.set(response)
        @.options.object.parent.populate_min_max_fields() # b/c value could be edited so that edited collection item is hidden by filter, so reset filter to make sure it stays in view
        @load()
      error : ->
        console.log "Changes were not saved, for some reason"
      start_callback : -> ractive.expand()
    return {
      teardown : (id)->
      update : (id)->
      }

  Ractive.DEBUG = false

  Ractive.decorators.inpage_edit = Collection.EditInPlace

  Collection.CollectionItemSubarea = Ractive.extend
    template : '#collection_item_subarea_template'
    computed :
      name : ->
        _(subareas).findWhere({id : @get('id')}).name

  Collection.CollectionItemArea = Ractive.extend
    template : '#collection_item_area_template'
    computed :
      name : ->
        _(areas).findWhere({id : @get('area_id')}).name
    components :
      collectionitemsubarea : Collection.CollectionItemSubarea

  Selectable =
    oninit : ->
      @select()
    toggle : ->
      @event.original.preventDefault()
      @event.original.stopPropagation()
      if @get("#{@get('attr')}_selected")
        @unselect()
      else
        @select()
    select : ->
      @root.add_filter(@get('attr'),@get('id'))
      @set("#{@get('attr')}_selected",true)
    unselect : ->
      @root.remove_filter(@get('attr'),@get('id'))
      @set("#{@get('attr')}_selected",false)

  SelectableArea = _.extend
    data :
      attr : "area"
  , Selectable

  SelectableSubarea = _.extend
    data :
      attr : "subarea"
  , Selectable

  Collection.SubareaFilter = Ractive.extend
    template : '#subarea_template'
  .extend SelectableSubarea

  Collection.AreaFilter = Ractive.extend
    template : '#area_filter_template'
    components :
      subarea : Collection.SubareaFilter
  .extend SelectableArea

  FileInput = (node)->
    $(node).on 'change', (event)->
      add_file(event,@)
    add_file = (event,el)->
      file = el.files[0]
      ractive = Ractive.getNodeInfo(el).ractive
      ractive.add_file(file)
      _reset_input()
    _reset_input = ->
      input = $(node)
      input.wrap('<form></form>').closest('form').get(0).reset()
      input.unwrap()
    return {
      teardown : ->
        $(node).off 'change'
        $(node).closest('.fileupload').find('.fileinput-button').off 'click'
      update : ->
        #noop
    }

  Ractive.decorators.ractive_fileupload = FileInput

  FileSelectTrigger = (node)->
    $(node).on 'click', (event)->
      source = Ractive.getNodeInfo(@).ractive # might be an archive doc (has document_group_id) or primary doc (no document_group_id)
      collection.set('document_target', source)
      #UserInput.terminate_user_input_request()
      #UserInput.reset()
      $('input:file').trigger('click')
    return {
      teardown : ->
        $(node).off 'click'
      update : ->
        #noop
    }

  Ractive.decorators.file_select_trigger = FileSelectTrigger

  Collection.File = Ractive.extend
    template : "#selected_file_template"
    deselect_file : ->
      @parent.deselect_file()

  EditBackup =
    stash : ->
      @stashed_instance = $.extend(true,{},_(@get()).omit("validation_criteria", "has_errors", "performance_indicator_required", "truncated_title", "delete_confirmation_message", "error_vector", "reminders_count", "notes_count", "model_name", "issue_context", "count", "model_name", "issue_context", "count", "include", "persisted", "match_vector","expanded","editing"))
    restore : ->
      @set(@stashed_instance)

  Collection.CollectionItem = Ractive.extend
    template : '#collection_item_template'
    components :
      collectionItemArea : Collection.CollectionItemArea
      file : Collection.File
    oninit : ->
      @set
        editing : false
        attachment_error:false
        single_attachment_error:false
        expanded:false
        serialization_key : item_name
    onconfig : ->
      @validator = new Validator(@)
    validate : ->
      @validator.validate()
    computed :
      validation_criteria: ->
        title : 'notBlank'
        attachment : =>
          return true if @get('model_name') == "advisory_council_issue" # attachments are optional and both are allowed
          valid_link = !_.isNull(@get('article_link')) && @get('article_link').length > 0
          valid_file = !_.isNull(@get('original_filename'))
          valid_link || valid_file
        single_attachment : =>
          return true if @get('model_name') == "advisory_council_issue" # attachments are optional and both are allowed
          valid_link = !_.isNull(@get('article_link')) && @get('article_link').length > 0
          valid_file = !_.isNull(@get('original_filename'))
          !(valid_link && valid_file)
        filesize : ['lessThan', @get('maximum_filesize'), {if : => @get('file')}]
        original_type : ['match', @get('permitted_filetypes'), {if : => @get('file')}]
      has_errors : ->
        @validator.has_errors()
      performance_indicator_required : -> false
      truncated_title : ->
        "\""+@get('title').split(' ').slice(0,4).join(' ') + "...\""
      delete_confirmation_message : ->
        delete_confirmation_message+@get('truncated_title')+"?"
      error_vector : ->
        title_error : @get('title_error')
        attachment_error : @get('attachment_error')
        single_attachment_error : @get('single_attachment_error')
        filesize_error : @get('filesize_error')
        original_type_error : @get('original_type_error')
      reminders_count : ->
        @get('reminders').length
      notes_count : ->
        @get('notes').length
      model_name : ->
        item_name
      issue_context : ->
        item_name == "advisory_council_issue"
      count : ->
        t = @get('title') || ""
        100 - t.length
      include : ->
        @get('editing') || !@get('persisted') ||
          (@_matches_title() &&
          @_matches_from() &&
          @_matches_to() &&
          @_matches_area_subarea())
      persisted : ->
        !_.isNull(@get('id'))
      match_vector : ->
        matches_from : @_matches_from()
        matches_to : @_matches_to()
        matches_area_subarea : @_matches_area_subarea()
        matches_area : @_matches_area()
        matches_subarea: @_matches_subarea()
        matches_title: @_matches_title()
    _matches_from : ->
      $.datepicker.parseDate("yy, M d",@get('date')) >= new Date(@get('filter_criteria.from'))
    _matches_to : ->
      $.datepicker.parseDate("yy, M d",@get('date')) <= new Date(@get('filter_criteria.to'))
    _matches_area_subarea : ->
      return (@_matches_area() || @_matches_subarea())
    _matches_area : ->
      return true if _.isEmpty(@get('area_ids'))
      matches = _.intersection(@get('area_ids'), @get('filter_criteria.areas'))
      matches.length > 0
    _matches_subarea : ->
      matches = _.intersection(@get('subarea_ids'), @get('filter_criteria.subareas'))
      matches.length > 0
    _matches_title : ->
      escaped_title = @get('filter_criteria.title').
                        replace(/\\/g,"\\\\").
                        replace(/(\?|\(|\)|\[|\]|\{|\}|\.|\>|\<)/g,"\\$1")
      re = new RegExp(escaped_title.trim(),"i")
      re.test @get('title')
    expand : ->
      @set('expanded',true)
      $(@find('.collapse')).collapse('show')
    compact : ->
      @set('expanded',false)
      $(@find('.collapse')).collapse('hide')
    remove_title_errors : ->
      @set('title_error',false)
    cancel : ->
      UserInput.reset()
      @parent.shift('collection_items')
    form : ->
      $('.form input, .form select')
    save : ->
      if @validate()
        url = @parent.get('create_collection_item_url')
        $.ajax
          method : 'post'
          url : url
          data : @formData()
          dataType : 'json'
          success : @update_collection_item
          processData : false
          contentType : false
      else
        #console.log JSON.stringify @get('error_vector')
    update_collection_item : (data,textStatus,jqxhr)->
      collection.set('collection_items.0', data)
      collection.populate_min_max_fields() # to ensure that the newly-added collection_item is included in the filter
      UserInput.reset()
      if !_.isUndefined(@edit)
        @edit.load() # terminate edit, if it was active, but don't try to restore stashed instance
    delete_callback : (data,textStatus,jqxhr)->
      @parent.delete(@)
    remove_errors : ->
      @compact() #nothing to do with errors, but this method is called on edit_cancel
      @restore()
    persistent_attributes : ->
      attrs = ['title', 'article_link', 'lastModifiedDate', 'area_ids', 'subarea_ids' ]
      attrs.push('file', 'lastModifiedDate', 'filesize', 'original_filename', 'original_type') unless typeof(@get('file')) == 'undefined'
      attrs.push('selected_performance_indicators_attributes') if item_name == "media_appearance"
      attrs
    formData : ->
      @asFormData @persistent_attributes()
    deselect_file : ->
      file_input = $(@find("##{item_name}_file"))
      # see http://stackoverflow.com/questions/1043957/clearing-input-type-file-using-jquery
      file_input.replaceWith(file_input.clone()) # the actual file input field
      @set('fileupload',null) # remove all traces!
      @set('original_filename',null) # remove all traces!
      @set('file','_remove')
      @validate()
    update_persist : (success, error, context)->
      if @validate()
        $.ajax
          url: @get('url')
          method : 'put'
          data : @formData()
          success : success
          context : context
          processData : false
          contentType : false
    download_attachment : ->
      window.location = @get('url')
    fetch_link : ->
      redirectWindow = window.open(@get('article_link'), '_blank')
      redirectWindow.location
    add_file : (file)->
      @set
        file : file
        filesize : file.size
        original_filename : file.name
        original_type : file.type
        lastModifiedDate : file.lastModifiedDate
      @validator.validate_attribute('filesize')
      @validator.validate_attribute('original_type')
      @validator.validate_attribute('attachment')
      @validator.validate_attribute('single_attachment')
    validate_attribute : (attribute)->
      @validator.validate_attribute(attribute)
  .extend PerformanceIndicatorAssociation
  .extend Remindable
  .extend Notable
  .extend ConfirmDeleteModal
  .extend EditBackup

  window.collection_items_data = -> # an initialization data set so that tests can reset between
    expanded : false
    collection_items: collection_items
    areas : areas
    create_collection_item_url: create_collection_item_url
    performance_indicator_url : Routes.media_appearance_media_appearance_performance_indicator_path(current_locale, 'id')
    planned_results : planned_results
    performance_indicators : performance_indicators
    item_name : item_name
    filter_criteria :
      title : selected_title
      from : new Date(new Date().toDateString()) # so that the time is 00:00, vs. the time of instantiation
      to : new Date(new Date().toDateString()) # then it yields proper comparison with Rails timestamp
      areas : []
      subareas : []
    permitted_filetypes : permitted_filetypes
    maximum_filesize : maximum_filesize

  window.options =
    el : '#collection_container'
    template : '#collection_template'
    data : window.collection_items_data()
    oninit : ->
      @populate_min_max_fields()
      @set('filter_criteria.title',@get('search_string_title_selector'))
    computed :
      title_filter : ->
        if !_.isNull(@get('search_string_title_selector'))
          @get('search_string_title_selector')
        else
          @get('filter_criteria.title')
      search_string_title_selector : ->
        unless _.isEmpty( window.location.search) || _.isNull( window.location.search)
          unescape(window.location.search.split("=")[1].replace(/\+/g,' '))
        else
          ''
      dates : ->
        _(@findAllComponents('collectionItem')).map (collectionItem)->
          if !_.isNull(collectionItem.get('date'))
            $.datepicker.parseDate("yy, M d",collectionItem.get('date'))
      earliest : ->
        @min('dates') unless _.isEmpty(@findAllComponents('collectionItem'))
      most_recent : ->
        @max('dates') unless _.isEmpty(@findAllComponents('collectionItem'))
      formatted_from_date:
        get: -> $.datepicker.formatDate("yy, M d", @get('filter_criteria.from'))
        set: (val)-> @set('filter_criteria.from', $.datepicker.parseDate( "yy, M d", val))
      formatted_to_date:
        get: -> $.datepicker.formatDate("yy, M d", @get('filter_criteria.to'))
        set: (val)-> @set('filter_criteria.to', $.datepicker.parseDate( "yy, M d", val))
    min : (param)->
      params = _(@get(param)).reject (p)-> _.isNull(p) || _.isUndefined(p)
      params.reduce (min,val)->
        return val if val<min && !_.isNull(val) && !_.isUndefined(val)
        min
    max : (param)->
      params = _(@get(param)).reject (p)-> _.isNull(p) || _.isUndefined(p)
      params.reduce (max,val)->
        return val if val > max && !_.isNull(val) && !_.isUndefined(val)
        max
    components :
      collectionItem : Collection.CollectionItem
      area : Collection.AreaFilter
    populate_min_max_fields : ->
      @set('filter_criteria.from',@get('earliest'))  unless _.isUndefined(@get('earliest'))
      @set('filter_criteria.to',@get('most_recent')) unless _.isUndefined(@get('most_recent'))
    expand : ->
      @set('expanded', true)
      _(@findAllComponents('collectionItem')).each (collectionItem)-> collectionItem.expand()
    compact : ->
      @set('expanded', false)
      _(@findAllComponents('collectionItem')).each (collectionItem)-> collectionItem.compact()
    add_filter : (attr,id)->
      @push("filter_criteria.#{attr}s",id)
    remove_filter : (attr,id)->
      i = _(@get("filter_criteria.#{attr}s")).indexOf(id)
      @splice("filter_criteria.#{attr}s",i,1)
    clear_filter : ->
      window.history.pushState({foo: "bar"},"unused title string",window.location.origin + window.location.pathname)
      @set('filter_criteria', _.extend(window.collection_items_data().filter_criteria, {title : ""}))
      _(collection.findAllComponents('area')).each (a)->a.select()
      _(collection.findAllComponents('subarea')).each (a)->a.select()
      @populate_min_max_fields()
    set_filter_from_query_string : ->
      search_string = if (_.isEmpty( window.location.search) || _.isNull( window.location.search)) then '' else window.location.search.split("=")[1].replace(/\+/g,' ')
      filter_criteria = _.extend(collection_items_data().filter_criteria,{title : unescape(search_string)})
      @set('filter_criteria',filter_criteria)
      _(collection.findAllComponents('area')).each (a)->a.select()
      _(collection.findAllComponents('subarea')).each (a)->a.select()
      @populate_min_max_fields()
    set_defaults : ->
      @clear_filter()
    new_article : ->
      @unshift('collection_items', $.extend(true,{},new_collection_item))
      $(@find("##{item_name}_title")).focus()
      UserInput.claim_user_input_request(@,'cancel')
    delete : (child)->
      index = @findAllComponents('collectionItem').indexOf(child)
      @splice('collection_items',index,1)
    cancel : ->
      @shift('collection_items')
    set_filter_criteria_to_date : (selectedDate)->
      @set('filter_criteria.to',$.datepicker.parseDate("yy, M d",selectedDate))
      $('#from').datepicker 'option', 'maxDate', selectedDate
      @update()
    set_filter_criteria_from_date : (selectedDate)->
      @set('filter_criteria.from',$.datepicker.parseDate("yy, M d",selectedDate))
      $('#to').datepicker 'option', 'minDate', selectedDate
      @update()
    add_file : (file)->
      @get('document_target').add_file(file)

  window.start_page = ->
    window.collection = new Ractive options
    filter_criteria_datepicker.start(collection)
    # so that a state object is present when returnng to the initial state with the back button
    # this is so we can discriminate returning to the page from page load
    history.replaceState({bish:"bosh"},"bash",window.location)

  start_page()

  window.onpopstate = (event)->
    if event.state # to ensure that it doesn't trigger on page load, it's a problem with phantomjs but not with chrome
      collection.set_filter_from_query_string()





