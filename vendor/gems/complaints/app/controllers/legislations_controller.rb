class LegislationsController < ApplicationController
  def create
    legislation = Legislation.create(legislation_params)
    render :json => legislation, :status => 200
  end

  def destroy
    legislation = Legislation.find(params[:id])
    legislation.destroy
    head 410
  end

  private
  def legislation_params
    params.require(:legislation).permit(:short_name, :full_name)
  end
end
