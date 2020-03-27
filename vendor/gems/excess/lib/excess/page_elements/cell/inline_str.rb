module Excess::PageElements
  module Cell
    class InlineStr < String
      def initialize(context, options)
        options = {:customFormat => "0"}.merge! options
        super context.render(:partial => 'excess/cell/inline_str', :formats => [:xml], :locals => options)
      end
    end
  end
end
