module Excess::PageElements
  module Cell
    class Number < String
      def initialize(context, options)
        super context.render(:partial => 'excess/cell/number', :formats => [:xml], :locals => options)
      end
    end
  end
end
