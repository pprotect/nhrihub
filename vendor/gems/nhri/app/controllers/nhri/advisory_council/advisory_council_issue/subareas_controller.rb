class Nhri::AdvisoryCouncil::AdvisoryCouncilIssue::SubareasController < SubareasController

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

  def subject_subarea
    Nhri::AdvisoryCouncil::AdvisoryCouncilIssueSubarea
  end
end
