class Nhri::AdvisoryCouncil::AdvisoryCouncilIssue::AreasController < AreasController

  def create
    super
  end

  def destroy
    super
  end

  private
  def subject_area
    Nhri::AdvisoryCouncil::AdvisoryCouncilIssueArea
  end
end
