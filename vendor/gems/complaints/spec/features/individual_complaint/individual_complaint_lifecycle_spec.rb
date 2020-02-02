require 'rails_helper'
require 'complaint_lifecycle'

feature "assessment status next step", js: true do

  let(:complaint){ FactoryBot.create( :individual_complaint, :with_associations, :assessment, assigned_to: @user, date_received: Date.today.advance(years: -2, days: -1)) }

  it_behaves_like 'complaint lifecycle'

end
