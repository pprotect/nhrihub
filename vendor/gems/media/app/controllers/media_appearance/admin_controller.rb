class MediaAppearance::AdminController < ApplicationController
  def index
    @media_filetypes = MediaAppearance.permitted_filetypes
    @media_filetype = Filetype.new
    @media_filesize = MediaAppearance.maximum_filesize
    @areas = MediaArea.all
    @create_subarea_url = media_appearance_area_subareas_path(I18n.locale, "area_id")
    @create_area_url = media_appearance_areas_path(I18n.locale)
  end
end
