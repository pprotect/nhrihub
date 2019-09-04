class MediaAppearance::SubareasController < SubareasController
  def subject_area
    MediaIssueArea
  end

  def subject_subarea
    MediaIssueSubarea
  end
end
