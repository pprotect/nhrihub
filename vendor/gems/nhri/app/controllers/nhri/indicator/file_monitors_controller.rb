class Nhri::Indicator::FileMonitorsController < ApplicationController
  include AttachedFile

  def create
    monitor = Nhri::FileMonitor.new(monitor_params)
    monitor.author = current_user
    if monitor.save
      render :json => monitor, :status => 200
    else
      head :internal_server_error
    end
  end

  def update
    monitor = Nhri::FileMonitor.find(params[:id])
    if monitor.update(monitor_params)
      render :json => monitor, :status => 200
    else
      head :internal_server_error
    end
  end

  def destroy
    monitor = Nhri::FileMonitor.find(params[:id])
    indicator = monitor.indicator
    if monitor.destroy
      render :json => indicator.reload, :status => 200
    else
      head :internal_server_error
    end
  end

  def show
    monitor = Nhri::FileMonitor.find(params[:id])
    send_blob monitor
  end

  private
  def monitor_params
    params[:monitor][:indicator_id] = params[:indicator_id]
    params.require(:monitor).permit(*permitted_attributes)
  end

  def permitted_attributes
    Nhri::FileMonitor::PermittedAttributes
  end
end
