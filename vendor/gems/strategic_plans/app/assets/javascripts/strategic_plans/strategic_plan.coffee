//= require 'in_page_edit'
//= require 'remindable'
//= require 'notable'
//= require 'confirm_delete_modal'
//= require 'ractive_validator'

$ ->
  Ractive.DEBUG = false

  MediaAppearance = Ractive.extend
    template : "#media_appearance_template"

  MediaAppearances = Ractive.extend
    template : "#media_appearances_template"
    components :
      'mediaappearance' : MediaAppearance

  Project = Ractive.extend
    template: "#project_template"

  Projects = Ractive.extend
    template : "#projects_template"
    components :
      'project' : Project

  PerformanceIndicator = Ractive.extend
    template : '#performance_indicator_template'
    oninit : ->
      @set
        validation_criteria :
          description : 'notBlank'
      @validator = new Validator(@)
    oncomplete : ->
      if @get('selected')
        @findParent('sp').open()
        @slide_into_view()
        @highlight()
    components :
      mediaappearances : MediaAppearances
      projects : Projects
    computed :
      selected : ->
        parseInt(window.selected_performance_indicator_id) == @get('id')
      persisted : ->
        !isNaN(parseInt(@get('id')))
      reminders_count : ->
        @get('reminders').length
      notes_count : ->
        @get('notes').length
      truncated_description : ->
        @get('description').split(' ').slice(0,4).join(' ')+"... etc."
      delete_confirmation_message : ->
        i18n.delete_performance_indicator_confirmation_message + "\""+@get('truncated_description')+"\"" + "?"
    remove_description_errors : ->
      @set("description_error","")
    create_save : ->
      context = $(@find('.new_performance_indicator'))
      url = @parent.get('create_performance_indicator_url')
      data = context.find(':input').serializeArray()
      data.push({name: 'performance_indicator[activity_id]', value : @get('activity_id')})
      if @validate()
        $.ajax
          type : 'post'
          url : url
          data : data
          dataType : 'json'
          success : @create_performance_indicator
          context : @
    validate : ->
      @validator.validate()
    create_performance_indicator : (response, statusText, jqxhr)->
      UserInput.reset()
      @set(response)
      @parent.show_add_performance_indicator()
    delete_callback : (resp, statusText, jqxhr)->
      UserInput.reset()
      @parent.set('performance_indicators',resp)
    remove_errors : ->
      @remove_description_errors()
    show_rules_panel : ->
      $('#rules_modal').modal('show')
    create_stop : ->
      UserInput.reset()
      @parent.remove_performance_indicator_form()
    edit_update : (performance_indicator) ->
      @set(performance_indicator)
    slide_into_view : ->
      $('html').animate({scrollTop:$("#performance_indicator_editable#{@get('id')}").offset().top-100},1000)
    highlight : ->
      $("#performance_indicator_editable#{@get('id')}").addClass('highlight')
    remove_highlight : ->
      $("#performance_indicator_editable#{@get('id')}").removeClass('highlight')
  .extend Remindable
  .extend Notable
  .extend ConfirmDeleteModal

  Activity = Ractive.extend
    template : '#activity_template'
    oninit : ->
      @set
        validation_criteria :
          description : 'notBlank'
      @validator = new Validator(@)
    components :
      pi : PerformanceIndicator
    computed :
      persisted : ->
        !isNaN(parseInt(@get('id')))
      truncated_description : ->
        @get('description').split(' ').slice(0,4).join(' ')+"... etc."
      delete_confirmation_message : ->
        i18n.delete_activity_confirmation_message + "\""+@get('truncated_description')+"\"" + "?"
      url : ->
        Routes.strategic_plans_outcome_activity_path('en',@get('outcome_id'),@get('id'))
      create_performance_indicator_url : ->
        Routes.strategic_plans_activity_performance_indicators_path('en',@get('id'))
    create_stop : ->
      UserInput.reset()
      @parent.remove_activity_form()
    create_save : ->
      url = @parent.get('create_activity_url')
      data = $(@find('.row.new_activity textarea')).serializeArray()
      data.push({name: 'activity[outcome_id]', value : @get('outcome_id')})
      if @validate()
        $.ajax
          type : 'post'
          url : url
          data : data
          dataType : 'json'
          success : @create_activity
          context : @
    validate : ->
      @validator.validate()
    create_activity : (response, statusText, jqxhr)->
      UserInput.reset()
      @set(response)
      @parent.show_add_activity()
    delete_callback : (resp, statusText, jqxhr)->
      UserInput.reset()
      @parent.set('activities', resp)
    remove_errors : ->
      @remove_description_errors()
    remove_description_errors : ->
      @set("description_error","")
    new_performance_indicator : ->
      new_performance_indicator_attributes =
            description : ''
            indexed_description: ''
            target: ''
            indexed_target: ''
            id : null
            activity_id : @get('id')
            url:null
            description_error:""
            progress:""
      @push('performance_indicators', new_performance_indicator_attributes)
      UserInput.claim_user_input_request(@,'remove_performance_indicator_form')
      @hide_add_performance_indicator()
    _add_performance_indicator : ->
      $(@.find('.performance_indicator_control'))
    hide_add_performance_indicator : ->
      @_add_performance_indicator().hide()
    show_add_performance_indicator : ->
      @_add_performance_indicator().show()
    remove_performance_indicator_form : ->
      if _.isNull(@findAllComponents('pi')[@get('performance_indicators').length-1].get('id'))
        @pop('performance_indicators')
      @show_add_performance_indicator()
    edit_update : (activity)->
      @set(activity)
  .extend ConfirmDeleteModal

  Outcome = Ractive.extend
    template : '#outcome_template'
    oninit : ->
      @set
        validation_criteria :
          description : 'notBlank'
      @validator = new Validator(@)
    computed :
      persisted : ->
        !isNaN(parseInt(@get('id')))
      truncated_description : ->
        @get('description').split(' ').slice(0,4).join(' ')+"... etc."
      delete_confirmation_message : ->
        i18n.delete_outcome_confirmation_message + "\""+@get('truncated_description')+"\"" + "?"
    components :
      activity : Activity
    create_stop : ->
      UserInput.reset()
      @parent.remove_outcome_form()
    create_save : ->
      url = @parent.get('create_outcome_url')
      data = $(@find('.row#new_outcome textarea')).serializeArray()
      data.push({name: 'outcome[planned_result_id]', value : @get('planned_result_id')})
      if @validate()
        $.ajax
          type : 'post'
          url : url
          data : data
          dataType : 'json'
          success : @create_outcome
          context : @
    validate : ->
      @validator.validate()
    create_outcome : (response, statusText, jqxhr)->
      UserInput.reset()
      @set(response)
      @parent.show_add_outcome()
    remove_description_errors : ->
      @set("description_error","")
    remove_errors : ->
      @remove_description_errors()
    delete_callback : (resp, statusText, jqxhr)->
      UserInput.reset()
      @parent.set('outcomes',resp)
    new_activity : ->
      new_activity_attributes =
                id: null
                outcome_id: @get('id')
                description: ''
                progress: null
                index: ''
                indexed_description: ''
                performance_indicators: []
                url: ''
                description_error: null
                #create_performance_indicator_url: ''
      @push('activities',new_activity_attributes)
      UserInput.claim_user_input_request(@,'remove_activity_form')
      @hide_add_activity()
    _add_activity : ->
      $(@.find('.activity_control'))
    hide_add_activity : ->
      @_add_activity().hide()
    show_add_activity : ->
      @_add_activity().show()
    remove_activity_form : ->
      if _.isNull(@findAllComponents('activity')[@get('activities').length-1].get('id'))
        @pop('activities')
      @show_add_activity()
    edit_update : (activity)->
      @set(activity)
  .extend ConfirmDeleteModal

  PlannedResult = Ractive.extend
    template : '#planned_result_template'
    oninit : ->
      if !@get('persisted')
        @parent.hide_add_planned_result()
      @set
        validation_criteria :
          description : 'notBlank'
      @validator = new Validator(@)
    computed :
      persisted : ->
        !isNaN(parseInt(@get('id')))
      truncated_description : ->
        @get('description').split(' ').slice(0,4).join(' ')+"... etc."
      delete_confirmation_message : ->
        i18n.delete_planned_result_confirmation_message + "\""+@get('truncated_description')+"\"" + "?"
    components :
      outcome : Outcome
    create_stop : ->
      UserInput.reset()
      @parent.remove_planned_result_form()
    create_save : ->
      url = @parent.get('create_planned_result_url')
      data = $(@find('textarea')).serializeArray()
      data.push({name: 'planned_result[strategic_priority_id]', value : @get('strategic_priority_id')})
      if @validate()
        $.ajax
          type : 'post'
          url : url
          data : data
          dataType : 'json'
          success : @create_pr
          context : @
    validate : ->
      @validator.validate()
    remove_description_errors : ->
      @set("description_error",false)
    remove_errors : ->
      @remove_description_errors()
    create_pr : (response, statusText, jqxhr)->
      UserInput.reset()
      @set(response)
      @parent.show_add_planned_result()
    update_pr : (response, statusText, jqxhr)->
      @set(response)
    delete_callback : (response, statusText, jqxhr)->
      UserInput.reset()
      @parent.set('planned_results',response)
    new_outcome : ->
      UserInput.claim_user_input_request(@,'remove_outcome_form')
      new_outcome_attributes =
              id: null
              planned_result_id: @get('id')
              description: ''
              index: ''
              indexed_description: ''
              url: ''
              create_activity_url: ''
              activities: []
              description_error: ''
      @push('outcomes',new_outcome_attributes)
      @hide_add_outcome()
    remove_outcome_form : ->
      if _.isNull(@findAllComponents('outcome')[@get('outcomes').length-1].get('id'))
        @pop('outcomes')
      @show_add_outcome()
    _add_outcome : ->
      $(@.find('.outcome_control'))
    hide_add_outcome : ->
      @_add_outcome().hide()
    show_add_outcome : ->
      @_add_outcome().show()
    edit_update : (planned_result)->
      @set(planned_result)
  .extend ConfirmDeleteModal

  # response to save is assumed to be an array of all
  # the strategic priorities on the page
  EditInPlace = (node,id)->
    ractive = @
    @edit = new InpageEdit
      on : node
      object : @
      focus_element : 'input.title'
      success : (response, textStatus, jqXhr)->
        ractive.edit_update(response)
        @load()
      error : ->
        console.log "Changes were not saved, for some reason"
    return {
      teardown : (id)->
        # ractive.edit.off()
      update : (id)->
        if _.isUndefined(id)
          # ractive.edit.off()
        else
          # item was added
          # enable EditInPlace for the node
          # @edit = new InpageEdit
          #   on : node
          #   object : @
          #   focus_element : 'input.title'
          #   success : (response, textStatus, jqXhr)->
          #     ractive = @.options.object
          #     # the whole dataset is replaced... Ractive figures out
          #     # what has changed and what to re-render
          #     strategic_plan.set('strategic_priorities',response)
          #     @.show()
          #   error : ->
          #     console.log "Changes were not saved, for some reason"
          }

  Ractive.decorators.inpage_edit = EditInPlace

  StrategicPriority = Ractive.extend
    oninit : ->
      @set
        validation_criteria :
          description : 'notBlank'
          priority_level : 'numeric'
      @validator = new Validator(@)
    onconfig : ->
      @set('original_description', @get('description'))
      @set('original_priority_level', @get('priority_level'))
    template : '#strategic_priority_template'
    components :
      pr : PlannedResult
    computed :
      length : ->
        if @get('description')
          @get('description').length
        else
          0
      count : ->
        Math.max(0,(100 - @get('length')))
      spid : ->
        window.strategic_plan.get('id')
      persisted : ->
        !isNaN(parseInt(@get('id')))
      delete_confirmation_message : ->
        i18n.delete_strategic_priority_confirmation_message + @get('priority_level')+ "?"
      create_planned_result_url : ->
        Routes.strategic_plans_strategic_priority_planned_results_path('en',@get('id'))
    new_planned_result: ->
      UserInput.claim_user_input_request(@,'remove_planned_result_form')
      new_planned_result_attributes = 
              create_outcome_url: ''
              description: ''
              description_error: null 
              id: null
              index: ''
              indexed_description: ''
              outcomes: []
              strategic_priority_id: @get('id')
              url: ''
      @push('planned_results', new_planned_result_attributes)
    cancel : ->
      UserInput.reset()
      @parent.get('strategic_priorities').shift() # it's only the first one that ever gets cancelled
    form : ->
      $(@find('#new_strategic_priority'))
    save : ->
      data = @form().serializeArray()
      url = @form().attr('action')
      if @validate(data)
        $.post(url, data, @update_sp, 'json')
    update_sp : (data,textStatus,jqxhr)->
      UserInput.reset()
      strategic_plan.set('strategic_priorities', data)
    delete_callback : (data,textStatus,jqxhr)->
      @update_sp(data,textStatus,jqxhr)
    validate : ->
      @validator.validate()
    remove_priority_level_errors : ->
      @set("priority_level_error",false)
    remove_description_errors : ->
      @set("description_error",false)
    remove_errors : ->
      @remove_priority_level_errors() && @remove_description_errors()
    _add_planned_result : ->
      $(@parent.el).
        find('.new_planned_result').
        closest('.row')
    hide_add_planned_result : ->
      @_add_planned_result().
        hide()
    show_add_planned_result : ->
      @_add_planned_result().
        show()
    remove_planned_result_form : ->
      if _.isNull(@findAllComponents('pr')[@get('planned_results').length-1].get('id'))
        @pop('planned_results')
      @show_add_planned_result()
    edit_update : (strategic_priorities)->
      @parent.set('strategic_priorities',strategic_priorities) # different from other components, b/c user may update the priority level. In others, index is not user-settable
    open : ->
      $( @find('.collapsed') ).removeClass('collapsed')
      $( @find('.collapse') ).addClass('in')
  .extend ConfirmDeleteModal

  window.strategic_plan = new Ractive
    el : "#strategic_plan"
    template: "#strategic_plan_template"
    data: strategic_plan_data
    components :
      sp : StrategicPriority
    new_strategic_priority : ->
      if @get('current')
        UserInput.claim_user_input_request(@,'remove_strategic_priorities_form')
        # add only if there are no strategic priorities
        # of if the most recent is persisted
        if @.findAllComponents().length == 0 || @.findComponent().get('persisted')
          strategic_plan.unshift('strategic_priorities', {id:null, description: '', priority_level:null} )
      else
        flash.notify()
    remove_strategic_priorities_form : ->
      @shift('strategic_priorities') # it's only the first one that ever gets cancelled

