require 'rails_helper'

describe "user's first password" do
  let(:user){ FactoryBot.create(:user) }

  it "leaves previous passwords empty" do
    expect(user.crypted_password).not_to be_nil
    expect(user.previous_passwords.count).to be_zero
    user.update(:password => "sekret&", :password_confirmation => "sekret&")
    expect(user.previous_passwords.count).to eq 1
  end
end

describe "user's second and subsequent passwords" do
  let(:user){ FactoryBot.create(:user) }
  let!(:initial_crypted_password){ user.crypted_password }
  let(:crypted_passwords){ [] }

  before do
    12.times do |i|
      user.update(:password => "sekret#{i}&", :password_confirmation => "sekret#{i}&")
      crypted_passwords << user.crypted_password
    end
  end

  it "moves the replaced password to previous passwords" do
    expect(user.previous_passwords.map(&:crypted_password)).to eq [initial_crypted_password]+crypted_passwords[0..10] # last one is not sent to previous passwords
  end
end

describe "maximum number of previous passwords saved" do
  let(:user){ FactoryBot.create(:user) }
  let(:crypted_passwords){ [] }

  before do
    15.times do |i|
      user.update(:password => "sekret#{i}&", :password_confirmation => "sekret#{i}&")
      crypted_passwords << user.crypted_password
    end
  end

  it "moves the replaced password to previous passwords" do
    expect(user.previous_passwords.map(&:crypted_password)).to eq crypted_passwords[2..13] # 12 are saved, last one (index 14) is not saved
  end
end
