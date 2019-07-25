class AddRequestParamsToAccessLog < ActiveRecord::Migration[6.0]
  def change
    add_column :access_events, :request_ip, :string
    add_column :access_events, :request_user_agent, :string
  end
end
