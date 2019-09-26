class ProjectsController < ApplicationController
  def index
    @areas = ProjectArea.all
    @subareas = ProjectSubarea.all
    @mandates = Mandate.all.sort_by(&:name)
    @projects = Project.all
    @agencies = Agency.all
    @planned_results = PlannedResult.all_with_associations
    @project_named_documents_titles = ProjectDocument::NamedProjectDocumentTitles
    @maximum_filesize = ProjectDocument.maximum_filesize * 1000000
    @permitted_filetypes = ProjectDocument.permitted_filetypes
    @create_reminder_url = project_reminders_path('en','id')
    @create_note_url     = project_notes_path('en','id')
    @all_users = User.select(:firstName, :lastName, :id).all
    render :index, :layout => 'application_webpack'
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
                        :mandate_id,
                        :project_documents_attributes => [:file, :title, :original_filename, :original_type],
                        :subarea_ids => [],
                        :agency_ids => [],
                        :performance_indicator_associations_attributes => [:association_id, :performance_indicator_id]]
    params.require(:project).permit(*permitted_params)
  end
end
