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
    populate_offices
  end

  def populate_offices
    with_capture 'Complaints::Engine', :offices, :office_groups, :provinces do

      STAFF.group_by{|s| s[:group]}.each do |office_group,offices|
        group = OfficeGroup.find_or_create_by(:name => office_group.titlecase) unless office_group.nil?
        offices.map{|o| o[:office]}.uniq.each do |oname|
          if group&.name =~ /provinc/i
            province = Province.find_or_create_by(:name => oname)
            Office.find_or_create_by(:office_group_id => group&.id, :province_id => province&.id )
          else
            Office.find_or_create_by(:name => oname, :office_group_id => group&.id)
          end
        end
      end

    end
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
private
  def create_user(login)
    #user = User.create(:login => login,
                #:email => Faker::Internet.email,
                #:enabled => true,
                #:firstName => Faker::Name.first_name,
                #:lastName => Faker::Name.last_name,
                #:organization => Organization.first,
                #:public_key => "BMQ+Q7yItYnNYQpzXJm0Eu+esfIDl3PkxQDNK//f0IF1CybZyFYy2VrON8d4riV3hWYzlJQn/hRHw3mWFG9Nj3M=",
                #:public_key_handle => "Ym9ndXNfMTQ3MjAxMTYxODU0OA")
    #user.update_attribute(:salt, '1641b615ad281759adf85cd5fbf17fcb7a3f7e87')
    #user.update_attribute(:activation_code, '9bb0db48971821563788e316b1fdd53dd99bc8ff')
    #user.update_attribute(:activated_at, DateTime.new(2011,1,1))
    #user.update_attribute(:crypted_password, '660030f1be7289571b0467b9195ff39471c60651')
    #create_roles(user, user.login, roles) # in this case, the name of the role is the same as the user's login!
    #user
    # USE SQL FOR SLIGHTLY FASTER TEST TIMES
    last_id = ActiveRecord::Base.connection.execute('select last_value from users_id_seq').first['last_value']
    next_id = last_id.succ
    # here the encrypted password is 'password#'
    sql = <<-SQL.squish
    insert into users (id, login, email, enabled, "firstName", "lastName", organization_id, public_key, public_key_handle,
                       salt, activation_code, activated_at, crypted_password, created_at, updated_at)
                values (#{next_id},
                        '#{login}', '#{Faker::Internet.email}', true, '#{Faker::Name.first_name}',
                        '#{Faker::Name.last_name.gsub(/'/,"''")}', '#{Organization.first&.id || FactoryBot.create(:organization).id}',
                        'BMQ+Q7yItYnNYQpzXJm0Eu+esfIDl3PkxQDNK//f0IF1CybZyFYy2VrON8d4riV3hWYzlJQn/hRHw3mWFG9Nj3M=',
                        'Ym9ndXNfMTQ3MjAxMTYxODU0OA',
                        '1641b615ad281759adf85cd5fbf17fcb7a3f7e87',
                        '9bb0db48971821563788e316b1fdd53dd99bc8ff',
                        timestamp '2011-01-01 01:01',
                        '16059ecc2a037f7b4b4edd9a5cfdd8bd87bb8150',
                        NOW()::timestamp,
                        NOW()::timestamp);
    SQL
    ActiveRecord::Base.connection.execute(sql)
    ActiveRecord::Base.connection.execute("alter sequence users_id_seq restart with #{next_id.succ};")
    user = User.last
    create_role(user, user.login) # in this case, the name of the role is the same as the user's login!
    user
  end

  def create_role(user, role)
    role = Role.create(:name => role)
    #Controller.update_table
    #actions.each { |a| role.actions << a  }
    user.roles << role
    user.save
  end

  def admin_roles
    Action.all
  end

  def staff_roles
    Action.
      all.
      reject{|a|
        a.controller_name =~ /authengine/ && 
          !(a.controller_name =~ /sessions/ && (a.action_name == "new" || a.action_name == "destroy")) # login/logout
      }.
      reject{|a| a.controller_name =~ /admin/}
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
      fill_in "Password", :with => "password#"
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
      fill_in "Mot de pass", :with => "password#"
      login_button.click
      wait_for_authentication
    end
  end
end
