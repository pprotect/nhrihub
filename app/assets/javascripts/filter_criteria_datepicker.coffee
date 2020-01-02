filter_criteria_datepicker = @filter_criteria_datepicker =
  start : (collection)->
    $('#from').datepicker
      changeMonth: true
      changeYear: true
      numberOfMonths: 3
      defaultDate: '+1w'
      maxDate: new Date
      yearRange: '1990:+0'
      dateFormat: "yy, M dd"
      constrainInput: false
      onChangeMonthYear: (year, month, inst) ->
        format = inst.settings.dateFormat
        selectedDate = new Date(inst.selectedYear,inst.selectedMonth,inst.selectedDay)
        date = $.datepicker.formatDate(format, selectedDate)
        $(this).datepicker("setDate", date)
        $(this).trigger('blur')
      onClose: (selectedDate) ->
        unless selectedDate == ""
          collection.set_filter_criteria_from_date(selectedDate)

    $('#to').datepicker
      maxDate: new Date()
      defaultDate: '+1w'
      changeMonth: true
      changeYear: true
      numberOfMonths: 3
      dateFormat: "yy, M dd"
      onChangeMonthYear: (year, month, inst) ->
        format = inst.settings.dateFormat
        selectedDate = new Date(inst.selectedYear,inst.selectedMonth,inst.selectedDay)
        date = $.datepicker.formatDate(format, selectedDate)
        $(this).datepicker("setDate", date)
        $(this).trigger('blur')
      onClose: (selectedDate) ->
        unless selectedDate == ""
          collection.set_filter_criteria_to_date(selectedDate)
