module Excess
  class Engine < Rails::Engine
    isolate_namespace Excess

    initializer 'excess.action_controller' do |app|
      ActiveSupport.on_load :action_controller_base do
        helper Excess::ExcessHelper
      end
    end

  end
end
