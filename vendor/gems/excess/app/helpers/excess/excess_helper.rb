module Excess
  module ExcessHelper
    def document_namespaces
      {"xmlns" => "http://schemas.openxmlformats.org/spreadsheetml/2006/main",
       "xmlns:r" => "http://schemas.openxmlformats.org/officeDocument/2006/relationships",
       "xmlns:mc" => "http://schemas.openxmlformats.org/markup-compatibility/2006",
       "mc:Ignorable" => "x14ac",
       "xmlns:x14ac" => "http://schemas.microsoft.com/office/spreadsheetml/2009/9/ac"}
    end

    def cell(options)
      case options[:type]
      when "inlineStr"
        Excess::PageElements::Cell::InlineStr.new(self, options)
      when "number"
        Excess::PageElements::Cell::Number.new(self, options)
      end
    end
  end
end
