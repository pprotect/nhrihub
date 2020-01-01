require 'rails_helper'

describe "complaint ordering" do
  before do
    @agency_z = FactoryBot.create(:agency, name: "Zazu")
    @agency_a = FactoryBot.create(:agency, name: "Abacus")
    @agency_u = FactoryBot.create(:agency, name: "Unassigned")
  end

  it "should place 'Unassigned' first'" do
    #this gives deprecation warnings in Rails 6.0
    #expect( Agency.unscoped.order("case when name='Unassigned' then 1 else 2 end, name") ).to eq [@agency_u, @agency_a, @agency_z]
    expect( Agency.unscoped.select("*, case when name='Unassigned' then 1 else 2 end as unassigned_first").order([:unassigned_first, :name]) ).to eq [@agency_u, @agency_a, @agency_z]
  end
end
