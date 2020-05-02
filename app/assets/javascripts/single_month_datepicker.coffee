SingleMonthDatepicker = (node)->
  $(node).datepicker
    #altField: $(node).attr['id'] can't use this b/c it doesn't trigger ractive change
    maxDate: null
    defaultDate: new Date()
    changeMonth: true
    changeYear: true
    numberOfMonths: 1
    dateFormat: "dd/mm/yy"
    onClose: (selectedDate) ->
      unless selectedDate == ""
        object = Ractive.getContext(node).ractive
        object.set('formatted_date',selectedDate)
        object.set('date',selectedDate)
        object.validate()
  if node.dataset.yearRange != ""
    $(node).datepicker('option', 'yearRange', node.dataset.yearRange)
  teardown : ->
    $(node).datepicker('destroy')
