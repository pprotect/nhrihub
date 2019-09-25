class Complaint::AreasController < AreasController
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
end
