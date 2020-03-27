Rails.application.routes.draw do
  mount Excess::Engine => "/excess"
  get "/test(.:format)", :to => "test#index", :as => :test
end
