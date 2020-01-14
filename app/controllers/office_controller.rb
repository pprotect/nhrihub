class OfficeController < ApplicationController
  def create
    params[:office][:office_group_id]=params.delete(:office_group_id)
    office = Office.new(office_params)
    if office.save
      render json: OfficeGroup.all, status: 200
    else
      head :internal_server_error
    end

  end

  def destroy
    office = Office.find(params[:id])
    if office.destroy
      render json: OfficeGroup.all
    else
      head :internal_server_error
    end
  end

  private
  def office_params
    params.require('office').permit('name', 'office_group_id')
  end
end
