class MediaAppearance::AdminController < ApplicationController
  def index
    @media_filetypes = MediaAppearance.permitted_filetypes
    @media_filetype = Filetype.new
    @media_filesize = MediaAppearance.maximum_filesize
    @areas = MediaIssueArea.all
    @subarea = MediaIssueSubarea.new
  end
end
