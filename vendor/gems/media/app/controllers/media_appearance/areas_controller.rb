class MediaAppearance::AreasController < ApplicationController
  def create
    area = MediaIssueArea.new(area_params)
    if area.save
      render :json => MediaIssueArea.all, :status => 200
    else
      head :internal_server_error
    end
  end

  def destroy
    area = MediaIssueArea.find(params[:id])
    if area.destroy
      render :json => MediaIssueArea.all, :status => 200
    else
      head :internal_server_error
    end
  end

  private
  def area_params
    params.require('area').permit(:name)
  end
end
