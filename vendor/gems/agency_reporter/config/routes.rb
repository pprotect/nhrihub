Rails.application.routes.draw do
  scope ':locale', locale: /#{I18n.available_locales.join("|")}/ do
    namespace :agency_reporter do
      resource :agency_list, only: [] do
        get :show, on: :collection
      end
    end
  end
end
