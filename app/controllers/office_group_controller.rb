class OfficeGroupController < ApplicationController
  def create
    office_group = OfficeGroup.new(office_group_params)
    if office_group.save
      render json: OfficeGroup.all, status: 200
    else
      render :head, status: 500
    end
  end

  def destroy
    office_group = OfficeGroup.find(params[:id])
    if office_group.destroy
      render json: OfficeGroup.all
    else
      render :head, status: 500
    end
  end

  private
  def office_group_params
    params.require('office_group').permit('name')
  end
end
