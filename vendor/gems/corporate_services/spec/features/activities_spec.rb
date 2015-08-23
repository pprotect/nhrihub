require 'rails_helper'
require 'login_helpers'
require 'navigation_helpers'
require_relative '../helpers/activities_spec_helpers'
require_relative '../helpers/strategic_plan_helpers'
require_relative '../helpers/setup_helpers'


feature "populate plannned result activities", :js => true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include ActivitiesSpecHelpers
  include StrategicPlanHelpers
  include SetupHelpers

  feature "add activity when there were none before" do
    before do
      sp = StrategicPlan.create(:start_date => 6.months.ago.to_date)
      spl = StrategicPriority.create(:strategic_plan_id => sp.id, :priority_level => 1, :description => "Gonna do things betta")
      pr = PlannedResult.create(:strategic_priority_id => spl.id, :description => "Something profound")
      o = Outcome.create(:planned_result_id => pr.id, :description => "ultimate enlightenment")
      visit corporate_services_strategic_plan_path(:en, "current")
      open_accordion_for_strategic_priority_one
      add_activity.click
    end

    scenario "add single activity item" do
      #expect(page).not_to have_selector("i.new_activity")
      fill_in 'new_activity_description', :with => "think really hard"
      fill_in 'new_activity_performance_indicator', :with => "steam rising"
      fill_in 'new_activity_target', :with => "88% achievement"
      fill_in 'new_activity_progress', :with => "nearly finished"
      expect{save_activity.click; sleep(0.2)}.to change{Activity.count}.from(0).to(1)
      expect(page).to have_selector(activity_selector + ".description", :text => "1.1.1.1 think really hard")
      expect(page).to have_selector(activity_selector + ".performance_indicator", :text => "1.1.1.1 steam rising")
      expect(page).to have_selector(activity_selector + ".target", :text => "1.1.1.1 88% achievement")
      expect(page).to have_selector(activity_selector + ".activity_progress", :text => "nearly finished")
    end

    scenario "try to save activity with blank description field" do
      #expect(page).not_to have_selector("i.new_activity")
      expect{save_activity.click; sleep(0.2)}.not_to change{Activity.count}
      expect(page).to have_selector("#description_error", :text => "You must enter a description")
    end

    scenario "try to save activity with whitespace description field" do
      #expect(page).not_to have_selector("i.new_activity")
      fill_in 'new_activity_description', :with => " "
      expect{save_activity.click; sleep(0.2)}.not_to change{Activity.count}
      expect(page).to have_selector("#description_error", :text => "You must enter a description")
    end

    scenario "add multiple activity items" do
      #expect(page).not_to have_selector("i.new_activity")
      fill_in 'new_activity_description', :with => "think really hard"
      fill_in 'new_activity_performance_indicator', :with => "steam rising"
      fill_in 'new_activity_target', :with => "88% achievement"
      fill_in 'new_activity_progress', :with => "nearly finished"
      expect{save_activity.click; sleep(0.2)}.to change{Activity.count}.from(0).to(1)
      expect(page).to have_selector(activity_selector + ".description", :text => "1.1.1.1 think really hard")
      expect(page).to have_selector(activity_selector + ".performance_indicator", :text => "1.1.1.1 steam rising")
      expect(page).to have_selector(activity_selector + ".target", :text => "1.1.1.1 88% achievement")
      expect(page).to have_selector(activity_selector + ".activity_progress", :text => "nearly finished")
      add_activity.click
      #expect(page).not_to have_selector("i.new_activity")
      fill_in 'new_activity_description', :with => "ruminate mightily"
      fill_in 'new_activity_performance_indicator', :with => "great insight"
      fill_in 'new_activity_target', :with => "full employment"
      fill_in 'new_activity_progress', :with => "completed"
      expect{save_activity.click; sleep(0.2)}.to change{Activity.count}.from(1).to(2)
      expect(page).to have_selector(activity_selector + ".description", :text => "1.1.1.2 ruminate mightily")
      expect(page).to have_selector(activity_selector + ".performance_indicator", :text => "1.1.1.2 great insight")
      expect(page).to have_selector(activity_selector + ".target", :text => "1.1.1.2 full employment")
      expect(page).to have_selector(activity_selector + ".activity_progress", :text => "completed")
      expect(page).to have_selector(activity_selector + ".description", :text => "1.1.1.1 think really hard")
      expect(page).to have_selector(activity_selector + ".performance_indicator", :text => "1.1.1.1 steam rising")
      expect(page).to have_selector(activity_selector + ".target", :text => "1.1.1.1 88% achievement")
      expect(page).to have_selector(activity_selector + ".activity_progress", :text => "nearly finished")
    end
  end

  feature "add activity to pre-existing" do
    before do
      setup_activity
      visit corporate_services_strategic_plan_path(:en, "current")
      open_accordion_for_strategic_priority_one
      add_activity.click
    end

    scenario "add activities item" do
      #expect(page).not_to have_selector("i.new_activity")
      fill_in 'new_activity_description', :with => "work really hard"
      fill_in 'new_activity_performance_indicator', :with => "great insight"
      fill_in 'new_activity_target', :with => "full employment"
      fill_in 'new_activity_progress', :with => "completed"
      expect{save_activity.click; sleep(0.2)}.to change{Activity.count}.from(1).to(2)
      expect(page).to have_selector(activity_selector + ".description", :text => "1.1.1.2 work really hard")
      expect(page).to have_selector(activity_selector + ".performance_indicator", :text => "1.1.1.2 great insight")
      expect(page).to have_selector(activity_selector + ".target", :text => "1.1.1.2 full employment")
      expect(page).to have_selector(activity_selector + ".activity_progress", :text => "completed")
    end
  end

end


feature "actions on existing activities", :js => true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include ActivitiesSpecHelpers
  include StrategicPlanHelpers

  before do
    sp = StrategicPlan.create(:start_date => 6.months.ago.to_date)
    spl = StrategicPriority.create(:strategic_plan_id => sp.id, :priority_level => 1, :description => "Gonna do things betta")
    pr = PlannedResult.create(:strategic_priority_id => spl.id, :description => "Something profound")
    o = Outcome.create(:planned_result_id => pr.id, :description => "whirled peas")
    Activity.create(:outcome_id => o.id, :description => "work hard", :performance_indicator => "great effort", :target => "15% improvement")
    Activity.create(:outcome_id => o.id, :description => "do the right thing", :performance_indicator => "things get better", :target => "85% improvement")
    visit corporate_services_strategic_plan_path(:en, "current")
    open_accordion_for_strategic_priority_one
  end

  scenario "delete the first of multiple activities" do
    page.all(activity_selector + ".description")[0].hover
    expect{ page.find(activity_selector + "span.delete_icon").click; sleep(0.2)}.to change{Activity.count}.from(2).to(1)
    expect(page.find(activity_selector + ".description").text).to eq "1.1.1.1 do the right thing"
    expect(page.find(activity_selector + ".performance_indicator").text).to eq "1.1.1.1 things get better"
    expect(page.find(activity_selector + ".target").text).to eq "1.1.1.1 85% improvement"
  end

  scenario "delete one of multiple activities, not the first" do
    page.all(activity_selector + ".description")[1].hover
    expect{ page.find(activity_selector + "span.delete_icon").click; sleep(0.2)}.to change{Activity.count}.from(2).to(1)
    expect(page.find(activity_selector + ".description").text).to eq "1.1.1.1 work hard"
    expect(page.find(activity_selector + ".performance_indicator").text).to eq "1.1.1.1 great effort"
    expect(page.find(activity_selector + ".target").text).to eq "1.1.1.1 15% improvement"
  end

  scenario "edit the first of multiple activities" do
    page.all(activity_selector + ".description div.no_edit span:nth-of-type(1)")[0].click
    activity_description_field.first.set("new description")
    activity_performance_indicator_field.first.set("new performance indicator")
    activity_target_field.first.set("total satisfaction")
    activity_progress_field.first.set("half completed")
    expect{ activity_save_icon.click; sleep(0.2) }.to change{ Activity.first.description }.to "new description"
    expect(page.all(activity_selector+".description .no_edit span:first-of-type")[0].text ).to eq "1.1.1.1 new description"
    expect(page.all(activity_selector+".performance_indicator .no_edit span:first-of-type")[0].text ).to eq "1.1.1.1 new performance indicator"
    expect(page.all(activity_selector+".target .no_edit span:first-of-type")[0].text ).to eq "1.1.1.1 total satisfaction"
    expect(page.all(activity_selector + ".activity_progress", :text => "completed")[0].text).to eq "half completed"
  end

  scenario "edit to blank description and cancel" do
    first_activity_description.click
    sleep(0.2)
    activity_edit_cancel.click
    expect(first_activity_description.text).to eq "1.1.1.1 work hard"
  end

  scenario "edit to blank description and cancel" do
    first_activity_description.click
    activity_description_field.first.set("")
    expect{ activity_save_icon.click; sleep(0.2) }.not_to change{ Activity.first.description }
    expect(page).to have_selector(".activity .description #description_error", :text => "You must enter a description")
    activity_edit_cancel.click
    sleep(0.2)
    # error msg disappears on cancel
    expect(page).not_to have_selector(".activity .description #description_error", :text => "You must enter a description")
    first_activity_description.click
    # error message doesn't reappear on re-edit
    expect(page).not_to have_selector(".activity .description #description_error", :text => "You must enter a description")
    # original value should be in the text area input field
    expect(activity_description_field.first.value).to eq "work hard"
  end

  scenario "edit one of multiple activities, not the first" do
    page.all(activity_selector + ".description div.no_edit span:nth-of-type(1)")[1].click
    activity_description_field.last.set("new description")
    activity_performance_indicator_field.last.set("new performance indicator")
    activity_target_field.last.set("total satisfaction")
    activity_progress_field.last.set("half completed")
    activity_save_icon.click
    sleep(0.4)
    # expect{}.to change{} fails for unknown reasons, so use this longer syntax
    expect(page.all(activity_selector+".description .no_edit span:first-of-type")[1].text ).to eq "1.1.1.2 new description"
    expect(page.all(activity_selector+".performance_indicator .no_edit span:first-of-type")[1].text ).to eq "1.1.1.2 new performance indicator"
    expect(page.all(activity_selector+".target .no_edit span:first-of-type")[1].text ).to eq "1.1.1.2 total satisfaction"
    expect(page.all(activity_selector + ".activity_progress .no_edit span:first-of-type")[1].text).to eq "half completed"
    expect( Activity.last.description ).to eq "new description"
  end
end
