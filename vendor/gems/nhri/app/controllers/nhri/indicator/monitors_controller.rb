class Nhri::Indicator::MonitorsController < ApplicationController
  def create
    monitor = model.new(monitor_params)
    monitor.author = current_user
    if monitor.save
      render :json => monitor.indicator.monitors, :status => 200
    else
      head :internal_server_error
    end
  end

  def update
    monitor = model.find(params[:id])
    if monitor.update(monitor_params)
      render :json => monitor, :status => 200
    else
      head :internal_server_error
    end
  end

  def destroy
    monitor = model.find(params[:id])
    if monitor.destroy
      render :json => monitor.indicator.monitors, :status => 200
    else
      head :internal_server_error
    end
  end

  private
  def monitor_params
    params[:monitor][:indicator_id] = params[:indicator_id]
    params.require(:monitor).permit(*permitted_attributes)
  end

  def model
    (@model ||= "Nhri::"+params[:monitor].delete(:type)).constantize
  end

  def permitted_attributes
    (model.to_s+"::PermittedAttributes").constantize
  end
end
