#= require 'ractive_validator'
#= require 'ractive_local_methods'
#= require 'confirm_delete_modal'
#= require 'remindable'
#= require 'notable'
$ ->
  Attribute = Ractive.extend
    template : "<div class='col-md-2' style='width:{{column_width}}%'> {{description}} </div>"
    computed :
      column_width : ->
        l = @parent.get('human_rights_attributes').length
        100/l

  Attributes = Ractive.extend
    template : "{{#human_rights_attributes}} <attribute description='{{description}}' /> {{/human_rights_attributes}}"
    components :
      attribute : Attribute

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
      update : ->
        #noop
    }

  Ractive.decorators.ractive_fileupload = FileInput

  SelectedFile = Ractive.extend
    template : "#selected_file_template"
    oninit : ->
      @set
        validation_criteria :
          filesize : ['lessThan', @get('maximum_filesize')]
          original_type : ['match', @get('permitted_filetypes')]
          file : =>
            !_.isEmpty(@get('name'))
      @validator = new Validator(@)
    computed :
      original_filename : -> @get('name')
      permitted_filetypes : -> window.permitted_filetypes
      maximum_filesize : -> window.maximum_filesize
      valid_file_selected : -> @get('name') != undefined
    persistent_attributes : ->
        [ 'filesize', 'original_filename', 'original_type', 'file']
    formData : ->
      @asFormData @persistent_attributes()
    deselect_file : ->
      @reset()
      @set
        validation_criteria :
          filesize : ['lessThan', @get('maximum_filesize')]
          original_type : ['match', @get('permitted_filetypes')]
    validate : ->
      @validator.validate()
    add_file : (file)->
      @set
        filesize: file.size
        name: file.name
        original_type: file.type
        file : file
      @validate()

  MonitorPopover = (node)->
    indicator = @
    $(node).popover
      html : true,
      title : ->
        $('#detailsTitle').html()
      content : ->
        data = indicator.get()
        if data.monitor_format == "numeric"
          template = "#numericMonitorDetailsContent"
        else if data.monitor_format == "text"
          template = "#textMonitorDetailsContent"
        else
          template = "#fileMonitorDetailsContent"
        ractive = new Ractive
          template : template
          data : data
        ractive.toHTML()
      template : $('#popover_template').html()
      trigger: 'hover'
    teardown: ->
      $(node).off('mouseenter')

  window.file_monitor = new Ractive
    el: "#file_monitor"
    template : "#file_monitor_template"
    computed :
      url : ->
        if @get('persisted')
          Routes.nhri_indicator_file_monitor_path(current_locale, @get('indicator_id'), @get('id'))
        else
          Routes.nhri_indicator_file_monitors_path(current_locale, @get('indicator_id'))
      persisted : ->
        !_.isUndefined @get('id')
      save_method : ->
        if @get('persisted')
          'put'
        else
          'post'
      serialization_key : -> 'monitor'
      delete_confirmation_message : ->
        delete_file_monitor_confirmation_message
      valid_file_selected: ->
        @findComponent('selectedFile').get('valid_file_selected')
    decorators :
      popover : MonitorPopover
    components :
      selectedFile : SelectedFile
    formData : ->
      @findComponent('selectedFile').formData()
    onModalClose : ->
      @findComponent('selectedFile').deselect_file()
    save_file : ->
      if @validate()
        $.ajax
          method : @get('save_method')
          url : @get('url')
          data : @formData()
          dataType : 'json'
          success : @update_file
          processData : false
          contentType : false
          context : @
    validate : ->
      @findComponent('selectedFile').validate()
    update_file : (response)->
      @findComponent('selectedFile').reset()
      @set(response)
      indicator_id = @get('indicator_id')
      indicator = _(heading.findAllComponents('indicator')).find (i)-> i.get('id')==indicator_id
      indicator.set('file_monitor.id',@get('id'))
    download_file : ->
      window.location = @get('url')
    #remove_selected_file : ->
      #@get('fileupload').files=[]
    add_file : (file)->
      @findComponent('selectedFile').add_file(file)
    delete_callback : (response, statusText, jqxhr) ->
      indicator_id = @get('indicator_id')
      @reset({indicator_id : indicator_id})
      @findComponent('selectedFile').reset()
      indicator = _(heading.findAllComponents('indicator')).find (i)-> i.get('id')==indicator_id
      indicator.set('file_monitor',null)

  $.extend window.file_monitor, ConfirmDeleteModal

  Indicator = Ractive.extend
    template : "#indicator_template"
    computed :
      selected : ->
        parseInt(window.selected_indicator_id) == @get('id')
      monitors_count : ->
        if @get('monitor_format') == "numeric"
          @get('numeric_monitors').length
        else if @get('monitor_format') == "text"
          @get('text_monitors').length
        else if _.isNumber @get('file_monitor.id')
          1
        else
          0
      reminders_count : ->
        @get('reminders').length
      notes_count : ->
        @get('notes').length
      create_reminder_url : ->
        Routes.nhri_indicator_reminders_path(current_locale,@get('id'))
      create_note_url : ->
        Routes.nhri_indicator_notes_path(current_locale,@get('id'))
      url : ->
        Routes.nhri_heading_indicator_path(current_locale,@get('heading_id'),@get('id'))
      truncated_title : ->
        @get('title').split(' ').slice(0,4).join(' ')+"..."
      delete_confirmation_message : ->
        "#{delete_indicator_confirmation_message} \"#{@get('truncated_title')}\"?"
    oncomplete : ->
      if @get('selected')
        @highlight()
        @slide_into_view()
    show_monitors_panel : ->
      type = @get('monitor_format')
      if type == 'file'
        if _.isNull(@get('file_monitor'))
          file_monitor.reset({indicator_id : @get('id')})
        else
          file_monitor.set(@get('file_monitor'))
        $('#file_monitor_modal').modal('show')
      else
        monitors.set
          numeric_monitors : @get('numeric_monitors')
          text_monitors : @get('text_monitors')
          numeric_monitor_explanation : @get('numeric_monitor_explanation')
          monitor_format : @get('monitor_format')
          indicator_id : @get('id')
          source : @
        $("##{type}_monitors_modal").modal('show')
    delete_callback : ->
      @parent.remove_indicator(@get('id'))
    edit_indicator : ->
      new_indicator.set(_(@get()).omit(['selected', 'monitors_count', 'reminders_count', 'notes_count', 'create_reminder_url', 'create_note_url', 'url', 'truncated_title', 'delete_confirmation_message']))
      new_indicator.set('source',@)
      $('#new_indicator_modal').modal('show')
    highlight : ->
      $(@find('.indicator')).addClass('highlight')
    slide_into_view : ->
      $('html').animate( {scrollTop:$(".indicator.highlight").offset().top-100}, 1000)
  .extend Remindable
  .extend Notable
  .extend ConfirmDeleteModal

  NatureHumanRightsAttribute = Ractive.extend
    template : "#nature_attribute_template"
    components :
      indicator : Indicator
    new_indicator : ->
      new_indicator.set
        title : ""
        nature : @get('nature')
        human_rights_attribute_id : @get('attribute_id')
        heading_id : @get('heading_id')
        monitor_format : ""
        id : null
      $('#new_indicator_modal').modal('show')
    remove_indicator : (id)->
      nature = @get('nature')
      indicators = nature+'_indicators'
      indicator_ids = _(@get(indicators)).map (i)-> i.id
      index = indicator_ids.indexOf(id)
      @splice(indicators,index,1)

  NatureAllHumanRightsAttributes = Ractive.extend
    template : "#nature_all_attributes_template"
    components :
      indicator : Indicator
    computed :
      indicators : ->
        @get("all_attribute_#{@get('name')}_indicators")
      indicator_ids : ->
        _(@get('indicators')).map (i)-> i.id
    new_indicator : ->
      new_indicator.set
        title : ""
        nature : @get('nature')
        human_rights_attribute_id : null
        heading_id : @get('heading_id')
        monitor_format : ""
        id : null
      $('#new_indicator_modal').modal('show')
    remove_indicator : (id)->
      index = @get('indicator_ids').indexOf(id)
      @splice("all_attribute_#{@get('nature')}_indicators",index,1)

  Nature = Ractive.extend
    template : "#nature_template"
    computed :
      collection_name : ->
        "all_attribute_"+@get('name')+"_indicators"
      all_attribute_indicators : ->
        @get(@get('collection_name'))
    components :
      natureHumanRightsAttribute : NatureHumanRightsAttribute
      natureAllHumanRightsAttributes : NatureAllHumanRightsAttributes

  Natures = Ractive.extend
    template : "#natures_template"
    components :
      nature : Nature

  window.heading = new Ractive
    el: "#heading"
    template : "#heading_template"
    data:
      id : heading_data.id
      human_rights_attributes : heading_data.human_rights_attributes
      natures : natures
      all_attribute_structural_indicators : heading_data.all_attribute_structural_indicators
      all_attribute_process_indicators : heading_data.all_attribute_process_indicators
      all_attribute_outcomes_indicators : heading_data.all_attribute_outcomes_indicators
    components :
      attributes : Attributes
      natures : Natures
    add_indicator : (indicator)-> # it's the create_heading callback
      nature = indicator.nature
      if _.isNull(indicator.human_rights_attribute_id) # all-attributes indicator
        @push("all_attribute_#{nature}_indicators",indicator)
      else # single-attribute indicator
        attribute_index = _(@get('human_rights_attributes').map (o)->o.id).indexOf(indicator.human_rights_attribute_id)
        @push("human_rights_attributes.#{attribute_index}.#{nature}_indicators",indicator)

# position the labels in the corner box, it depends on column height
  window.position_labels = ->
    height = $('.row-eq-height').height()
    width = $('#corner').width()
    ll_vert_pos = (height/2) + (height-50)/3
    ll_right_pos = 51-(height-50)/8
    hr_left_pos = 44+(height-50)/44
    $('#low-left').css('top', ll_vert_pos+'px').css('right',ll_right_pos+'px').show()
    $('#high-right').css('bottom',height/2+'px').css('left',hr_left_pos+'px').show()
  position_labels()





