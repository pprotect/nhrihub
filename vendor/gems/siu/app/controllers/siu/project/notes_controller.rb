require 'notes_controller'

class Siu::Project::NotesController < NotesController
  def create
    super
  end

  def update
    super
  end

  def destroy
    super
  end

  private
  def note_params
    params[:note][:notable_id] = params[:project_id]
    params[:note][:notable_type] = "Siu::Project"
    super
  end
end
