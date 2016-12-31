class RemindersController < ApplicationController
  def create
    reminder = Reminder.new(reminder_params)
    remindable = reminder.remindable
    if reminder.save
      render :json => Reminder.includes(:user, :remindable).where(:remindable_id => reminder.remindable_id, :remindable_type => reminder.remindable_type), :status => 200
    else
      head :internal_server_error
    end
  end

  def update
    reminder = Reminder.find(params[:id])
    if reminder.update_attributes(reminder_params)
      render :json => reminder, :status => 200
    else
      head :internal_server_error
    end
  end

  def destroy
    reminder = Reminder.find(params[:id])
    remindable = reminder.remindable
    if reminder.destroy
      render :json => remindable.reload.reminders, :status => 200
    else
      head :internal_server_error
    end
  end

  private
  def reminder_params
    params.require(:reminder).permit(:reminder_type, :start_date, :text, :remindable_id, :remindable_type, :user_id )
  end
end
