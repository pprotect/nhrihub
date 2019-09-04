class SubareasController < ApplicationController
  def create
    params[:subarea][:area_id] = params[:area_id]
    subarea = subject_subarea.new(subarea_params)
    if subarea.save
      render :json => subject_area.all
    else
      head :internal_server_error
    end
  end

  def destroy
    subarea = subject_subarea.find(params[:id])
    if subarea.destroy
      render :json => subject_area.all, :status => 200
    else
      head :internal_server_error
    end
  end

  private
  def subarea_params
    params.require('subarea').permit(:name, :area_id)
  end
end
