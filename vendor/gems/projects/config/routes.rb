Rails.application.routes.draw do
  scope ':locale', locale: /#{I18n.available_locales.join("|")}/ do
    resources :projects
    resources :project_performance_indicators, :only => :destroy
    resources :projects do
      notes_reminder_concern('project')
    end
    namespace :project_document do
      file_attachment_concern
    end
    resources :project_documents, :only => [:destroy, :show]
    resource :project_admin, :only => :show, :to => 'project_admin#show'
    namespace :project do
      resources :areas, :only => [:create, :destroy] do
        resources :subareas, :only => [:create, :destroy]
      end
    end
  end
end
