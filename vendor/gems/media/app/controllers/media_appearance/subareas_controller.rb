class MediaAppearance::SubareasController < SubareasController
  def create
    super
  end

  def destroy
    super
  end

  private
  def subject_area
    MediaArea
  end

  def subject_subarea
    MediaSubarea
  end
end
