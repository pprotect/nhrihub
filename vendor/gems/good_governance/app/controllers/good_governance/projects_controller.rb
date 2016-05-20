require 'project_document'

class GoodGovernance::ProjectsController < ApplicationController
  def index
    @projects = GoodGovernance::Project.all
    @mandates = Mandate.all
    @model_name = GoodGovernance::Project.to_s
    @i18n_key = @model_name.tableize.gsub(/\//,'.')
    @agencies = Agency.all
    @conventions = Convention.all
    @planned_results = PlannedResult.all_with_associations
    @project_types = ProjectType.mandate_groups
    @project_named_documents_titles = ProjectDocument::NamedProjectDocumentTitles
    @maximum_filesize = ProjectDocument.maximum_filesize * 1000000
    @permitted_filetypes = ProjectDocument.permitted_filetypes.to_json 
    @create_reminder_url = good_governance_project_reminders_path('en','id')
    @create_note_url     = good_governance_project_notes_path('en','id')
    render 'projects/index'
  end
end
