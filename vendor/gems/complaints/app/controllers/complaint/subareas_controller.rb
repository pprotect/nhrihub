class Complaint::SubareasController < SubareasController
  def create
    super
  end

  def destroy
    super
  end

  private
  def subject_area
    ComplaintArea
  end

  def subject_subarea
    ComplaintSubarea
  end
end
