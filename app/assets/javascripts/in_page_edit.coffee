##############
# IN-PAGE EDIT
##############
#  example usage
#    new @InpageEdit
#      on : node
#      focus_element : 'input.title'
#      success : (response, textStatus, jqXhr)->
#        id = response.id
#        source = $("table.document[data-id='"+id+"']").closest('.template-download')
#        new_template = _.template($('#template-download').html())
#        source.replaceWith(new_template({file:response}))
#      error : ->
#        console.log "Changes were not saved, for some reason"
#
#  options:
#    on: the root element of the editable content, a jquery node reference NOT the id, but the actual jquery object
#    focus_element : selector of element on which to apply focus when switching to edit mode
#    success : callback when save was successful
#    error : callback when save failed
#
#  requirements:
#    Needs an element with selector '.editable_container' with data attribute for save_url
#    Alternatively the url may be an attribute on the object being edited.
#
#  Stash is the saving of the original attributes when editing is commenced, so that they can be
#  restored if editing is cancelled. Two stash mechanisms are supported
#  1. InpageEdit stash
#    Editable elements should be of the form:
#        .col-md-2.date{'data-toggle'=>:edit, 'data-attribute'=>:date, :style => "width:15%"}
#          .fade.no_edit.in
#            %span {{ date }}
#          .fade.edit{:style => "margin-top:26px;"}
#            %input{:type => :text, value =>'{{ date }}'}
#   where data-attribute carries the name of the attribute to be stashed for a given element
#
#  2. Object stash
#    Where the object implements its own stash/restore methods


#= require 'user_input_manager'

class @InpageEditElement
  constructor : (@el,@object,@attribute) ->

  switch_to_edit : (stash)->
    unless _.isUndefined(@attribute) # in which case it's a control element not an input
      if stash # object will stash and restore itself if stash is false
        @_stash() # save the value for restoral after cancel when changes have been made
    @hide(@text())
    @show(@input())

  _stash : ->
    unless _.isArray(@attribute)
      @attribute = [@attribute]
    _(@attribute).each (attr)=>
      @object.set('original_'+attr,@object.get(attr))

  switch_to_show : ->
    @load()
    unless _.isUndefined(@attribute) # in which case it's a control element not an input
      @_restore()

  load : ->
    @show(@text())
    @hide(@input())

  _restore : ->
    unless _.isArray(@attribute)
      @attribute = [@attribute]
    _(@attribute).each (attr)=>
      unless _.isUndefined(@object.get("original_"+attr))
        @object.set(attr,@object.get("original_"+attr))

  input_field : ->
    @input().find('input')

  input : ->
    $(@el).find('.edit')

  text : ->
    $(@el).find('.no_edit')

  text_width : ->
    @text().find(':first-child').width()

  show : (element)->
    element.addClass('in')

  hide : (element)->
    element.removeClass('in')

InpageEditElement = @InpageEditElement

class @InpageEdit
  constructor : (options)->
    @options = options
    node = options.on
    options.object.editor = @
    if _.isFunction(options.object.validate)
      validate = true
    else
      validate = false

    @root =
      if $(@options.on).hasClass('editable_container')
        $(@options.on)
      else
        $(@options.on).find('.editable_container')

    $(@options.on).find("*").on 'click', "#edit_start", (e)=>
      e.stopPropagation()
      $target = $(e.target)
      @edit_start($target)

    $(@options.on).find("*").on 'click', '#edit_cancel', (e)=>
      e.stopPropagation()
      $target = $(e.target)
      @edit_cancel($target)

    $(@options.on).find("*").on 'click', '#edit_save', (e)=>
      e.stopPropagation()
      $target = $(e.target)
      if $target.closest('.editable_container').get(0) == @root.get(0)
        if validate && !@options.object.validate()
          return
        @context = $target.closest('.editable_container')
        url = @options.object.get('url')
        if _.isFunction(@options.object.persisted_attributes) # pull the data from the object
          data = @options.object.persisted_attributes()
          data['_method'] = 'put'
        else
          data = @context.find(':input').serializeArray() # pull the data from the dom
          data[data.length] = {name : '_method', value : 'put'}

        if _.isFunction(@options.object.update_persist) # situations where a fileupload must be handled are delegated to the ractive object
          @options.object.update_persist(@_success,@options.error,@)
        else
          ajax_options =
            url: url
            method : 'post'
            data : data
            success : @_success
            error : @options.error
            context : @
          if @options.headers
            ajax_options.headers = @options.headers

          $.ajax ajax_options

  edit_start : ($target) ->
    if $target.closest('.editable_container').get(0) == @root.get(0)
      if @options.before_edit_start
        @options.before_edit_start()
      @context = $target.closest('.editable_container')
      if _.isFunction(@options.object.stash)
        @options.object.stash()
        @edit(false)
      else
        @edit(true)
      @options.object.set('editing',true)
      @context.find(@options.focus_element).first().focus()
      if @options.start_callback
          @options.start_callback()

  edit_cancel : ($target)->
      if $target.closest('.editable_container').get(0) == @root.get(0)
        if _.isFunction(@options.object.restore)
          @options.object.restore()
        UserInput.reset()
        @context = $target.closest('.editable_container')
        @options.object.set('expanded',false)
        @_remove_pending_document_uploads()
        @_remove_errors()
        @show()

  _remove_errors : ->
    keys = _(@options.object.get()).keys()
    re = new RegExp(/_error$/)
    error_attrs = _(keys).select (k)-> re.test(k)
    _(error_attrs).each (a)=> @options.object.set(a,false)
    @options.object.findAllComponents().forEach (component)=>
      if !_.isUndefined(component.remove_errors)
        component.remove_errors()

  _remove_pending_document_uploads : ->
    pending_uploads = _(@options.object.findAllComponents('attachedDocument')).select (doc)-> !doc.get('persisted')
    _(pending_uploads).each (upload)-> upload.remove_file()

  _success : (response, textStatus, jqXhr)->
    UserInput.reset()
    @options.object.set('editing',false)
    @options.success.apply(@, [response, textStatus, jqXhr])

  off : ->
    $('body').off 'click',"#{@options.on}_edit_start"
    $('body').off 'click',"#{@options.on}_edit_cancel"
    $('body').off 'click',"#{@options.on}_edit_save"

  edit : (stash)->
    _(@elements()).each (el,i) ->
      el.switch_to_edit(stash)
    UserInput.claim_user_input_request(@options.object.editor, 'show')
    @options.object.set('editing',true)

  show : ->
    @options.object.remove_errors()
    _(@elements()).each (el,i) ->
      el.switch_to_show()
    @options.object.set('editing',false)

  load : ->
    _(@elements()).each (el,i) ->
      el.load()

  # must select only elements pertaining to this instance
  # nested in-page edits must be excluded from elements
  elements : ->
    @context = $(@options.on)
    all_elements = @context.find("[data-toggle='edit']")
    elements = _(all_elements).filter (el)=>
                      $(el).closest('.editable_container').get(0) == @root.get(0)
    elements.map (el,i)=>
      object = @options.object
      attribute = $(el).data('attribute')
      new InpageEditElement(el,object,attribute)

InpageEdit = @InpageEdit
