class Project::SubareasController < SubareasController
  def create
    super
  end

  def destroy
    super
  end

  private
  def subject_area
    ProjectArea
  end

  def subject_subarea
    ProjectSubarea
  end
end
