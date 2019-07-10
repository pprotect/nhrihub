class ProjectsController < ApplicationController
  def index
    @projects = Project.all
    @areas = Mandate.all
    @agencies = Agency.all
    @conventions = Convention.all
    @planned_results = PlannedResult.all_with_associations
    @project_types = ProjectType.mandate_groups
    @project_named_documents_titles = ProjectDocument::NamedProjectDocumentTitles
    @maximum_filesize = ProjectDocument.maximum_filesize * 1000000
    @permitted_filetypes = ProjectDocument.permitted_filetypes
    @create_reminder_url = project_reminders_path('en','id')
    @create_note_url     = project_notes_path('en','id')
  end

  def create
    project = Project.new(project_params)
    if project.save
      render :json => project.to_json, :status => 200
    else
      head :internal_server_error
    end
  end

  def update
    project = Project.find(params[:id])
    if project.update(project_params)
      render :json => project.to_json, :status => 200
    else
      head :internal_server_error
    end
  end

  def destroy
    project = Project.find(params[:id])
    project.destroy
    head :ok
  end

  private
  def project_params
    permitted_params = [:title,
                        :description,
                        :type,
                        :file,
                        :project_documents_attributes => [:file, :title, :original_filename, :original_type],
                        :area_ids => [],
                        :project_type_ids => [],
                        :agency_ids => [],
                        :convention_ids => [],
                        :performance_indicator_associations_attributes => [:association_id, :performance_indicator_id]]
    params.require(:project).permit(*permitted_params)
  end
end
