xml.instruct! :xml, :standalone => 'yes'

xml.worksheet document_namespaces do # document_namespaces is a helper from the Excess engine
  xml.cols do
    xml.col :min => "1", :max => "14", :customWidth => "1", :width => "34"
  end
  xml.sheetData do
    # the following are helpers in vendor/gems/complains/app/helpers/complaints/validation_helpers.rb
    xml << header
    xml << errors
    xml << totals
  end
  xml << mergeCells

end #/worksheet

