class MediaAppearance::SubareasController < SubareasController
  def subject_area
    MediaArea
  end

  def subject_subarea
    MediaSubarea
  end
end
