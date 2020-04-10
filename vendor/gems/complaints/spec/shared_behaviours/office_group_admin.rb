require 'office_group_office_admin_common_helpers'
require 'login_helpers'

RSpec.shared_examples  "office and office group admin" do

  feature "configure description office_groups and offices", :js => true do
    include LoggedInEnAdminUserHelper # sets up logged in admin user
    include OfficeGroupOfficeAdminCommonHelpers

    before do
      visit complaint_admin_show_path('en') 
    end

    scenario 'default office_groups and offices' do
      office_groups = STAFF.map{|s| s[:group].titlecase unless s[:group].nil? }.uniq.compact
      expect(page.all('.office_group .text').map(&:text)).to match_array office_groups
    end

    scenario 'add an office_group' do
      page.find('#office_group_name').set('What else')
      expect{ page.find('button#add_office_group').click; wait_for_ajax}.to change{ OfficeGroup.count }.by 1
      expect(page.all('.office_group .text').map(&:text)).to include "What else"
    end

    scenario 'add an office_group with blank text' do
      expect{ find('button#add_office_group').click; wait_for_ajax}.not_to change{ OfficeGroup.count }
      expect( page.find('#office_group_error') ).to have_text "Office group can't be blank"
    end

    scenario 'add an office_group with whitespace text' do
      page.find('#office_group_name').set('    ')
      expect{ find('button#add_office_group').click; wait_for_ajax}.not_to change{ OfficeGroup.count }
      expect( page.find('#office_group_error') ).to have_text "Office group can't be blank"
    end

    scenario 'add an office_group with leading/trailing whitespace' do
      page.find('#office_group_name').set('     What else       ')
      expect{ find('button#add_office_group').click; wait_for_ajax}.to change{ OfficeGroup.count }.by 1
      expect(page.all('.office_group .text').map(&:text)).to include "What else"
    end

    scenario 'blank office_group error message removed on keydown' do
      page.find('#office_group_name').set('    ')
      page.find('button#add_office_group').click
      wait_for_ajax
      expect( page.find('#office_group_error') ).to have_text "Office group can't be blank"
      name_field = page.find("#office_group_name").native
      name_field.send_keys("!")
      expect( page ).not_to have_selector('#office_group_error')
    end

    scenario 'view offices of an office_group' do
      open_accordion_for_office_group("Provincial Offices")
      office_names = ["Gauteng", "Mpumalanga", "North West", "Western Cape",
                 "KwaZulu-Natal", "Limpopo", "Free State", "Northern Cape",
                 "Eastern Cape"]
      expect(offices).to match_array office_names
    end

    scenario 'add a office' do
      open_accordion_for_office_group("Provincial Offices")
      page.find('#office_name').set('Another office')
      expect{ page.find('#add_office').click; wait_for_ajax}.to change{ Office.count }.by 1
      expect(offices).to include "Another office"
    end

    scenario 'add a office with blank text' do
      open_accordion_for_office_group("Provincial Offices")
      expect{ find('#add_office').click; wait_for_ajax}.not_to change{ Office.count }
      expect( page.find('#office_error') ).to have_text "Office can't be blank"
    end

    scenario 'add a office with whitespace text' do
      open_accordion_for_office_group("Provincial Offices")
      page.find('#office_name').set('   ')
      expect{ page.find('#add_office').click; wait_for_ajax}.not_to change{ Office.count }
      expect( page.find('#office_error') ).to have_text "Office can't be blank"
    end

    scenario 'add a office with leading/trailing whitespace' do
      open_accordion_for_office_group("Provincial Offices")
      page.find('#office_name').set('    Another office   ')
      expect{ page.find('#add_office').click; wait_for_ajax}.to change{ Office.count }.by 1
      expect(offices).to include "Another office"
    end

    scenario 'blank office error message removed on keydown' do
      open_accordion_for_office_group("Provincial Offices")
      find('#add_office').click
      wait_for_ajax
      expect( page.find('#office_error') ).to have_text "Office can't be blank"
      name_field = page.find("#office_name").native
      name_field.send_keys("!")
      expect( page ).not_to have_selector('#office_error', :visible => true)
    end

    scenario 'delete an office_group' do
      expect{click_delete_for("Provincial Offices"); wait_for_ajax}.to change{OfficeGroup.count}.by(-1).
        and change{Office.count}.by(-9)
      expect(page.all('.office_groups .office_group').length).to eq 2
    end

    scenario 'delete a office' do
      expect{click_delete_for("Provincial Offices", "Gauteng"); wait_for_ajax}.to change{Office.count}.by(-1)
      expect(offices.length).to eq 8
    end
  end
end
