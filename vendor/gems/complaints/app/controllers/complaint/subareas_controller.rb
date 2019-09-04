class Complaint::SubareasController < SubareasController
  def subject_area
    ComplaintArea
  end

  def subject_subarea
    ComplaintSubarea
  end
end
