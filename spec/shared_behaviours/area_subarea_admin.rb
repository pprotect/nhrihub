require 'area_subarea_admin_common_helpers'
require 'login_helpers'

RSpec.shared_examples "area subarea admin" do

  feature "configure description areas and subareas", :js => true do
    include LoggedInEnAdminUserHelper # sets up logged in admin user
    include AreaSubareaAdminCommonHelpers

    before do
      create_default_areas
      visit admin_page
    end

    scenario 'default areas and subareas' do
      areas = [ "Human Rights", "Good Governance", "Special Investigations Unit", "Corporate Services"]
      expect(page.all('.area .text').map(&:text)).to match_array areas
    end

    scenario 'add an area' do
      page.find('#area_name').set('What else')
      expect{ page.find('button#add_area').click; wait_for_ajax}.to change{ area_model.count }.by 1
      expect(page.all('.area .text').map(&:text)).to include "What else"
    end

    scenario 'add an area with blank text' do
      expect{ find('button#add_area').click; wait_for_ajax}.not_to change{ area_model.count }
      expect( page.find('#area_error') ).to have_text "Area can't be blank"
    end

    scenario 'add an area with whitespace text' do
      page.find('#area_name').set('    ')
      expect{ find('button#add_area').click; wait_for_ajax}.not_to change{ area_model.count }
      expect( page.find('#area_error') ).to have_text "Area can't be blank"
    end

    scenario 'add an area with leading/trailing whitespace' do
      page.find('#area_name').set('     What else       ')
      expect{ find('button#add_area').click; wait_for_ajax}.to change{ area_model.count }.by 1
      expect(page.all('.area .text').map(&:text)).to include "What else"
    end

    scenario 'blank area error message removed on keydown' do
      page.find('#area_name').set('    ')
      page.find('button#add_area').click
      wait_for_ajax
      expect( page.find('#area_error') ).to have_text "Area can't be blank"
      name_field = page.find("#area_name").native
      name_field.send_keys("!")
      expect( page ).not_to have_selector('#area_error')
    end

    scenario 'view subareas of an area' do
      open_accordion_for_area("Human Rights")
      subareas = [ "Violation", "Education activities", "Office reports",
                   "Universal periodic review", "CEDAW", "CRC", "CRPD" ]
      expect(subareas).to match_array subareas
    end

    scenario 'add a subarea' do
      open_accordion_for_area("Human Rights")
      page.find('#subarea_name').set('Another subarea')
      expect{ page.find('#add_subarea').click; wait_for_ajax}.to change{ subarea_model.count }.by 1
      expect(subareas).to include "Another subarea"
    end

    scenario 'add a subarea with blank text' do
      open_accordion_for_area("Human Rights")
      expect{ find('#add_subarea').click; wait_for_ajax}.not_to change{ subarea_model.count }
      expect( page.find('#subarea_error') ).to have_text "Subarea can't be blank"
    end

    scenario 'add a subarea with whitespace text' do
      open_accordion_for_area("Human Rights")
      page.find('#subarea_name').set('   ')
      expect{ page.find('#add_subarea').click; wait_for_ajax}.not_to change{ subarea_model.count }
      expect( page.find('#subarea_error') ).to have_text "Subarea can't be blank"
    end

    scenario 'add a subarea with leading/trailing whitespace' do
      open_accordion_for_area("Human Rights")
      page.find('#subarea_name').set('    Another subarea   ')
      expect{ page.find('#add_subarea').click; wait_for_ajax}.to change{ subarea_model.count }.by 1
      expect(subareas).to include "Another subarea"
    end

    scenario 'blank subarea error message removed on keydown' do
      open_accordion_for_area("Human Rights")
      find('#add_subarea').click
      wait_for_ajax
      expect( page.find('#subarea_error') ).to have_text "Subarea can't be blank"
      name_field = page.find("#subarea_name").native
      name_field.send_keys("!")
      expect( page ).not_to have_selector('#subarea_error', :visible => true)
    end

    scenario 'delete an area' do
      expect{click_delete_for("Human Rights"); wait_for_ajax}.to change{area_model.count}.by(-1).
        and change{subarea_model.count}.by(-7)
      expect(page.all('.areas .area').length).to eq 3
    end

    scenario 'delete a subarea' do
      expect{click_delete_for("Human Rights", "Violation"); wait_for_ajax}.to change{subarea_model.count}.by(-1)
      expect(subareas.length).to eq 6
    end
  end
end
