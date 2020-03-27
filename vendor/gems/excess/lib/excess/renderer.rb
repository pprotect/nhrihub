ActionController::Renderers.add :xlsx do |filename, options|
  doc = Excess::Spreadsheet.new(view_assigns)
  @rels = Excess::Rels.new
  options.merge!({:rels => @rels})
  doc.contents render_to_string(options) # looks for a <:action_name>.builder file, should be provided by host application
  @rels.create_file

  send_data doc.render_to_string, :filename => "#{filename}.xlsx",
    :type => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    :disposition => "attachment"
end
