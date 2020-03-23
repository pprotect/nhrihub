class AgenciesController < ApplicationController
  def create
    type = agency_params[:type].constantize
    agency = type.create(agency_params)
    render :json => agency, :status => 200
  end

  def destroy
    agency = Agency.find(params[:id])
    agency.destroy
    render :status => 410
  end

  private
  def agency_params
    params.require(:agency).permit(:name, :type, :province_id, :district_id)
  end
end
