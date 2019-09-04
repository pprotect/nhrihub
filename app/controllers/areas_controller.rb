class AreasController < ApplicationController
  def create
    area = subject_area.new(area_params)
    if area.save
      render :json => subject_area.all, :status => 200
    else
      head :internal_server_error
    end
  end

  def destroy
    area = subject_area.find(params[:id])
    if area.destroy
      render :json => subject_area.all, :status => 200
    else
      head :internal_server_error
    end
  end

  private
  def area_params
    params.require('area').permit(:name)
  end
end
