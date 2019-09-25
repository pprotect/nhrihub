class Project::SubareasController < SubareasController
  def subject_area
    ProjectArea
  end

  def subject_subarea
    ProjectSubarea
  end
end
