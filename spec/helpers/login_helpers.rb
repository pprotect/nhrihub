require 'rspec/core/shared_context'
require 'ie_remote_detector'
require_relative '../../vendor/gems/authengine/spec/helpers/user_setup_helper'

module RegisteredUserHelper
  extend RSpec::Core::SharedContext
  include UserSetupHelper

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("two_factor_authentication").and_return("enabled")
    @user = create_user('admin')
    @staff_user = create_user('staff')
    allow_any_instance_of(AuthorizedSystem).to receive(:permitted?).and_return(true)
    allow_any_instance_of(ApplicationController).to receive(:action_permitted?).and_return(true)
    allow_any_instance_of(ApplicationHelper).to receive(:permissions_granted?).and_return(true)
  end

  def remove_user_two_factor_authentication_credentials(user)
    user = User.where(:login => user).first
    user.update(:public_key => nil, :public_key_handle => nil)
  end

  def login_button
    page.find('.btn#sign_up')
  end

  def configure_keystore
    js = <<-JS.squish
      record = {"626f6775735f31343732303131363138353438":{ appId : "https://#{SITE_URL}", counter : 26, generated : "2016-08-24T04:11:36.812Z", keyHandle : "626f6775735f31343732303131363138353438", private : "219c8b4c622a837e981d7aef8ca7fe360d662203b051d3e430705c4e84289562", public : "04c43e43bc88b589cd610a735c99b412ef9eb1f2039773e4c500cd2bffdfd081750b26d9c85632d95ace37c778ae2577856633949427fe1447c37996146f4d8f73"}};
      replaceKeyStore (record);
    JS
    page.execute_script(js)
  end

end

module LoggedInEnAdminUserHelper
  extend RSpec::Core::SharedContext
  include RegisteredUserHelper
  include IERemoteDetector
  before do
    allow_any_instance_of(AuthenticatedSystem).to receive(:login_from_session).and_return(@user)
  end
end

module RealLoggedInEnAdminUserHelper
  extend RSpec::Core::SharedContext
  include RegisteredUserHelper
  include IERemoteDetector
  before do
    visit "/en"
    configure_keystore
    #unless ie_remote?(page) # IE doesn't delete cookies and terminate session between scenarios, so no need for login
    if page.has_selector?("h1", :text => "Please log in")
      fill_in "User name", :with => "admin"
      fill_in "Password", :with => "password"
      login_button.click # triggers ajax request for challenge, THEN form submit
      wait_for_authentication
    end
    #causes errors only in performance_indicators_spec.rb!! don't know why
    #resize_browser_window
  end
end


module LoggedInFrAdminUserHelper
  extend RSpec::Core::SharedContext
  include RegisteredUserHelper
  include IERemoteDetector
  before do
    visit "/fr"
    configure_keystore
    if page.has_selector?("h1", :text => "S'il vous plaît connecter")
      fill_in "Nom d'usilateur", :with => "admin"
      fill_in "Mot de pass", :with => "password"
      login_button.click
      wait_for_authentication
    end
  end
end
