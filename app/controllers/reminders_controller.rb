class RemindersController < ApplicationController
  def create
    reminder = Reminder.new(reminder_params)
    if reminder.save
      render :json => reminder.siblings, :status => 200
    else
      head :internal_server_error
    end
  end

  def update
    reminder = Reminder.find(params[:id])
    if reminder.update(reminder_params)
      render :json => reminder, :status => 200
    else
      head :internal_server_error
    end
  end

  def destroy
    reminder = Reminder.find(params[:id])
    if reminder.destroy
      # TODO why can't we just return status 410 ?
      render :json => reminder.siblings, :status => 200
    else
      head :internal_server_error
    end
  end

  private
  def reminder_params
    params.require(:reminder).permit(:reminder_type, :start_date, :text, :remindable_id, :remindable_type, :user_id )
  end
end
