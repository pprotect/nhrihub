class Complaint::CommunicationsController < ApplicationController
  def create
    # incoming date presumed to be in app's time zone
    # saved in utc equivalent
    communication = Communication.new(communication_params)
    communication.user = current_user
    if communication.save
      render :json => communication.complaint.communications, :status => 200
    else
      render :status => 500
    end
  end

  def destroy
    communication = Communication.find(params[:id])
    complaint = communication.complaint
    if communication.destroy
      render :json => complaint.reload.communications, :status => 200
    else
      render :status => 500
    end
  end

  def update
    communication = Communication.find(params[:id])
    if communication.update(communication_params)
      render :json => communication, :status => 200
    else
      render :status => 500
    end
  end

  private
  def communication_params
    params.require(:communication).permit(:user_id, :complaint_id, :direction, :mode, :formatted_date, :note,
                                          :communication_documents_attributes => [:file, :title, :original_filename, :original_type, :filesize, :lastModifiedDate],
                                          :communicants_attributes => [:name])
  end
end
