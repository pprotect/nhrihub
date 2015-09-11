$ ->
  MediaSubarea = Ractive.extend
    template : '#media_subarea_template'
    computed :
      name : ->
        _(subareas).findWhere({id : @get('id')}).name

  MediaArea = Ractive.extend
    template : '#media_area_template'
    computed :
      name : ->
        _(areas).findWhere({id : @get('area_id')}).name
    components :
      mediasubarea : MediaSubarea

  Metric = Ractive.extend
    template : '#metric_template'

  Subarea = Ractive.extend
    template : '#subarea_template'
    oninit : ->
      @unselect()
    toggle : ->
      @event.original.preventDefault()
      @event.original.stopPropagation()
      if @get('subarea_selected')
        @unselect()
      else
        @select()
    select : ->
      @root.add_subarea_filter(@get('id'))
      @set('subarea_selected',true)
    unselect : ->
      @root.remove_subarea_filter(@get('id'))
      @set('subarea_selected',false)

  Area = Ractive.extend
    template : '#area_template'
    components :
      subarea : Subarea
    oninit : ->
      @unselect()
    toggle : ->
      @event.original.preventDefault()
      @event.original.stopPropagation()
      if @get('area_selected')
        @unselect()
      else
        @select()
    select : ->
      _(@findAllComponents('subarea')).each (sa)-> sa.select()
      @root.add_area_filter(@get('id'))
      @set('area_selected',true)
    unselect : ->
      _(@findAllComponents('subarea')).each (sa)-> sa.unselect()
      @root.remove_area_filter(@get('id'))
      @set('area_selected',false)

  MediaAppearance = Ractive.extend
    template : '#media_appearance_template'
    components :
      mediaarea : MediaArea
      metric : Metric
    computed :
      area_ids : ->
        _(@get('media_areas')).map (ma)-> ma.area_id
      subarea_ids : ->
        ids = _(@get('media_areas')).map((ma)-> ma.subarea_ids)
        _(ids).flatten()
      include : ->
        @_matches_title() && @_matches_from() && @_matches_to() && @_matches_area() && @_matches_subarea()
    _matches_from : ->
      new Date(@get('date')) >= new Date(@get('sort_criteria.from'))
    _matches_to : ->
      new Date(@get('date')) <= new Date(@get('sort_criteria.to'))
    _matches_area : ->
      if @get('sort_criteria.areas').length > 0
        matches = _.intersection(@get('area_ids'), @get('sort_criteria.areas'))
        matches.length > 0
      else
        true
    _matches_subarea : ->
      if @get('sort_criteria.subareas').length > 0
        matches = _.intersection(@get('subarea_ids'), @get('sort_criteria.subareas'))
        matches.length > 0
      else
        true
    _matches_people_affected : ->
    _matches_violation_severity : ->
    _matches_violation_coefficient : ->
    _matches_positivity_rating : ->
    _matches_title : ->
      re = new RegExp(@get('sort_criteria.title'),'i')
      re.test(@get('title'))
    expand : ->
      $(@find('.collapse')).collapse('show')
    compact : ->
      $(@find('.collapse')).collapse('hide')

  window.media = new Ractive
    el : '#media_appearances'
    template : '#media_appearances_template'
    data :
      expanded : false
      media_appearances: media_appearances
      areas : areas
      sort_criteria :
        title : ""
        from : new Date(1995,0,1)
        to : new Date()
        areas : []
        subareas : []
    components :
      ma : MediaAppearance
      area : Area
    expand : ->
      @set('expanded', true)
      _(@findAllComponents('ma')).each (ma)-> ma.expand()
    compact : ->
      @set('expanded', false)
      _(@findAllComponents('ma')).each (ma)-> ma.compact()
    add_area_filter : (id) ->
      @push('sort_criteria.areas',id)
    remove_area_filter : (id) ->
      i = _(@get('sort_criteria.areas')).indexOf(id)
      @splice('sort_criteria.areas',i,1)
    add_subarea_filter : (id) ->
      @push('sort_criteria.subareas',id)
    remove_subarea_filter : (id) ->
      i = _(@get('sort_criteria.subareas')).indexOf(id)
      @splice('sort_criteria.subareas',i,1)