#require 'spec_helper'
require 'rails_helper'

describe "model uniqueness validation" do
  before do
    FactoryBot.create(:organization, :name => "Food for you")
    @org = FactoryBot.build(:organization, :name => "Food for you")
    @org.valid?
  end

  it "should populate the error message" do
    expect( @org.errors.full_messages.join(" ")).to include("Organization name already exists, organization name must be unique.")
  end
end

