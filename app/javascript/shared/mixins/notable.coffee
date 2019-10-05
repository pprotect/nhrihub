export default
  show_notes_panel : ->
    window.notes.set
      notes : @get('notes')
      create_note_url : @get('create_note_url')
      parent : @
    $('#notes_modal').modal('show')
