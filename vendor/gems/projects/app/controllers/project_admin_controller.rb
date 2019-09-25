class ProjectAdminController < ApplicationController
  def show
    @project_document_filetypes = ProjectDocument.permitted_filetypes
    @filetype = Filetype.new
    @filesize = ProjectDocument.maximum_filesize
    @areas = ProjectArea.all
    @create_subarea_url = project_area_subareas_path(I18n.locale, "area_id")
    @create_area_url = project_areas_path(I18n.locale)
  end
end
