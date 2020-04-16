require 'rails_helper'

feature "access events logger", js: true do
  describe "BlankPasswordExpiryToken " do
    let(:blank_password_expiry_token_path){ admin_expired_password_path("en","") }
    let(:exception){ AccessEvent.first.exception_type }
    it "should create and render an access event" do
      expect{visit(blank_password_expiry_token_path)}.to change{ AccessEvent.count }.by 1
      expect(exception).to eq "user/blank_password_expiry_token"
    end
  end

  describe "record not found with password expiry token" do
    let(:invalid_password_expiry_token_path){ admin_expired_password_path("en","1234") }
    let(:exception){ AccessEvent.first.exception_type }
    it "should create and render an access event" do
      expect{visit(invalid_password_expiry_token_path)}.to change{ AccessEvent.count }.by 1
      expect(exception).to eq "user/invalid_password_expiry_token"
    end
  end

  # not currently implemented
  #describe "BlankReplacementTokenRegistrationCode" do
    #let(:blank_replacement_token_registration_code){ admin_register_new_token_request_path("en","") }
    #it "should create and render an access event" do
      #expect{visit(blank_replacement_token_registration_code)}.to change{ AccessEvent.count }.by 1
    #end
  #end

  # not currently implemented
  #describe "TokenError" do
    #it "should create and render an access event" do
      #test_fail_placeholder
    #end
  #end

  describe "LoginNotFound", type: :request do
    let(:login_not_found){ post "/en/authengine/sessions", params: {login: "something", password: "anything"} }
    let(:exception){ AccessEvent.first.exception_type }
    it "should create and render an access event" do
      expect{login_not_found}.to change{ AccessEvent.count }.by 1
      expect(exception).to eq "user/login_not_found"
    end
  end

  describe "InvalidPassword", type: :request do
    let!(:user) do
      # password is 'password#'
      query =<<-QUERY
        insert into users (\"firstName\",\"lastName\",\"login\",\"crypted_password\",\"activated_at\")
                    values('Norman','Normal','opensesame','16059ecc2a037f7b4b4edd9a5cfdd8bd87bb8150','#{DateTime.now}')
      QUERY
      ActiveRecord::Base.connection.execute(query)
    end
    let(:invalid_password_request){ post "/en/authengine/sessions", params: {login: "opensesame", password: "password#"} }
    let(:exception){ AccessEvent.first.exception_type }

    it "should create and render an access event" do
      expect{invalid_password_request}.to change{ AccessEvent.count }.by 1
      expect(exception).to eq "user/invalid_password"
    end
  end

  describe "LoginBlank", type: :request do
    let!(:user) do
      # password is 'password#'
      query =<<-QUERY
        insert into users (\"firstName\",\"lastName\",\"login\",\"crypted_password\",\"activated_at\")
                    values('Norman','Normal','opensesame','16059ecc2a037f7b4b4edd9a5cfdd8bd87bb8150','#{DateTime.now}')
      QUERY
      ActiveRecord::Base.connection.execute(query)
    end
    let(:blank_login_request){ post "/en/authengine/sessions", params: {login: "", password: "password#"} }
    let(:exception){ AccessEvent.first.exception_type }

    it "should create and render an access event" do
      expect{blank_login_request}.to change{ AccessEvent.count }.by 1
      expect(exception).to eq "user/login_blank"
    end
  end

  #describe "TokenNotRegistered" do
    #it "should create and render an access event" do
      #test_fail_placeholder
    #end
  #end

  describe "AccountNotActivated", type: :request do
    let!(:user) do
      query =<<-QUERY
        insert into users (\"firstName\",\"lastName\",\"login\",\"crypted_password\")
                    values('Norman','Normal','opensesame','16059ecc2a037f7b4b4edd9a5cfdd8bd87bb8150')
      QUERY
      ActiveRecord::Base.connection.execute(query)
    end
    let(:login_request){ post "/en/authengine/sessions", params: {login: "opensesame", password: "password#"} }
    let(:exception){ AccessEvent.first.exception_type }

    it "should create and render an access event" do
      expect{login_request}.to change{ AccessEvent.count }.by 1
      expect(exception).to eq "user/account_not_activated"
    end
  end

  describe "AccountDisabled", type: :request do
    let!(:user) do
      # password is 'password#'
      query =<<-QUERY
        insert into users (\"firstName\",\"lastName\",\"login\",\"crypted_password\",\"activated_at\",\"enabled\")
                    values('Norman','Normal','opensesame','16059ecc2a037f7b4b4edd9a5cfdd8bd87bb8150','#{DateTime.now}',false)
      QUERY
      ActiveRecord::Base.connection.execute(query)
    end
    let(:login_request){ post "/en/authengine/sessions", params: {login: "opensesame", password: "password#"} }
    let(:exception){ AccessEvent.first.exception_type }

    it "should create and render an access event" do
      expect{login_request}.to change{ AccessEvent.count }.by 1
      expect(exception).to eq "user/account_disabled"
    end
  end

  describe "user/expired_password_replacement", type: :request do
    let(:password_expiry_token){ "anystringwillwork" }
    let!(:user) do
      # password is 'password#'
      query =<<-QUERY
        insert into users (\"firstName\",\"lastName\",\"login\",\"crypted_password\",\"activated_at\",\"enabled\",\"password_expiry_token\",\"email\")
                    values('Norman','Normal','opensesame','16059ecc2a037f7b4b4edd9a5cfdd8bd87bb8150','#{DateTime.now}',true,'#{password_expiry_token}','norm@normco.co.uk')
      QUERY
      ActiveRecord::Base.connection.execute(query)
    end
    let(:change_expired_password_request){ post "/en/admin/change_expired_password/#{password_expiry_token}", params: {user: {password: "foobar##", password_confirmation: "foobar##"}} }
    let(:exception){ AccessEvent.first.exception_type }

    it "should create and render an access event" do
      expect{change_expired_password_request}.to change{ AccessEvent.count }.by 1
      expect(exception).to eq "user/expired_password_replacement"
    end
  end

  describe "user/admin_reset_password_replacement", type: :request do
    let(:password_reset_code){ "anystringwillwork" }
    let!(:user) do
      # password is 'password#'
      query =<<-QUERY
        insert into users (\"firstName\",\"lastName\",\"login\",\"crypted_password\",\"activated_at\",\"enabled\",\"password_reset_code\",\"email\")
                    values('Norman','Normal','opensesame','16059ecc2a037f7b4b4edd9a5cfdd8bd87bb8150','#{DateTime.now}',true,'#{password_reset_code}','norm@normco.co.uk')
      QUERY
      ActiveRecord::Base.connection.execute(query)
    end
    let(:reset_password_replacement_request){ post "/en/admin/change_password/#{password_reset_code}", params: {user: {password: "foobar##", password_confirmation: "foobar##"}} }
    let(:exception){ AccessEvent.first.exception_type }

    it "should create and render an access event" do
      expect{reset_password_replacement_request}.to change{ AccessEvent.count }.by 1
      expect(exception).to eq "user/admin_reset_password_replacement"
    end
  end

  describe "user/failed_login_disable", type: :request do
    let!(:user) do
      # password is 'password#'
      query =<<-QUERY
        insert into users (\"firstName\",\"lastName\",\"login\",\"crypted_password\",\"activated_at\",\"enabled\",\"email\",\"failed_login_count\")
                    values('Norman','Normal','opensesame','16059ecc2a037f7b4b4edd9a5cfdd8bd87bb8150','#{DateTime.now}',true,'norm@normco.co.uk',2)
      QUERY
      ActiveRecord::Base.connection.execute(query)
    end
    let(:failed_login_request){ post "/en/authengine/sessions", params: {login: "opensesame", password: "badpassword#"} }
    let(:exception){ AccessEvent.first.exception_type }

    it "should create and render an access event" do
      expect{failed_login_request}.to change{ AccessEvent.count }.by 1
      expect(exception).to eq "user/failed_login_disable"
    end
  end

end
