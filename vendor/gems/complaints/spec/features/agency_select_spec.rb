require 'rails_helper'
require 'login_helpers'
require 'complaints_spec_setup_helpers'
require 'complaints_spec_helpers'

feature "agency select", js: true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include ComplaintsSpecSetupHelpers
  include ComplaintsSpecHelpers

  let(:complaint){ IndividualComplaint.first }

  before do
    populate_database(:individual_complaint, agency_count: 1)
    visit complaint_path(:en, complaint.id)
    edit_complaint
  end

  describe "select a national agency" do
    before do
      select('National', from:'agencies_select')
    end

    it "should present a dropbox with the 3 national categories" do
      expect(page).to have_selector('select#national_agencies_select')
      expect(page.all('select#national_agencies_select option').count).to eq Agency::NationalTypes.length + 1
    end

    describe "select national government agencies" do
      let(:number_of_government_agencies){ NationalGovernmentAgency.count }
      let(:selected_government_agency){ NationalGovernmentAgency.first }

      before do
        select('National government agencies', from: 'national_agencies_select')
      end

      it "should present a dropbox with all the national agencies" do
        expect(page).to have_selector('#government_agencies_select')
        expect(page.all('#government_agencies_select option').count).to eq number_of_government_agencies + 1
      end

      describe "select one of the government agencies" do
        it "should add the selected government agency to the complaint" do
          select(selected_government_agency.name, from: 'government_agencies_select')
          edit_save
          expect(complaint.agency_ids).to eq [selected_government_agency.id]
          expect(page.find('#agencies').text).to eq selected_government_agency.name
        end
      end
    end

    describe "select national government institutions" do
      let(:number_of_government_institutions ){ NationalGovernmentInstitution.count }
      let(:selected_government_institution){ NationalGovernmentInstitution.first }

      before do
        select('National government institutions', from: 'national_agencies_select')
      end

      it "should present a dropbox with all the government institutions" do
        expect(page).to have_selector('#government_agencies_select')
        expect(page.all('#government_agencies_select option').count).to eq number_of_government_institutions + 1
      end

      describe "select one of the government institutions" do
        it "should add the selected government institution to the complaint" do
          select(selected_government_institution.name, from: 'government_agencies_select')
          edit_save
          expect(complaint.agency_ids).to eq [selected_government_institution.id]
          expect(page.find('#agencies').text).to eq selected_government_institution.name
        end
      end
    end

    describe "select democracy-supporting institutions" do
      let(:number_of_democracy_institutions){ DemocracySupportingStateInstitution.count }
      let(:selected_democracy_institution){ DemocracySupportingStateInstitution.first }

      before do
        select('Democracy-supporting government institutions', from: 'national_agencies_select')
      end

      it "should present a dropbox with all the national agencies" do
        expect(page).to have_selector('#government_agencies_select')
        expect(page.all('#government_agencies_select option').count).to eq number_of_democracy_institutions + 1
      end

      describe "select one of the democracy institutions" do
        it "should add the selected democracy institution to the complaint" do
          select(selected_democracy_institution.name, from: 'government_agencies_select')
          edit_save
          expect(complaint.agency_ids).to eq [selected_democracy_institution.id]
          expect(page.find('#agencies').text).to eq selected_democracy_institution.name
        end
      end
    end
  end

  describe "select a provincial agency" do
    let(:number_of_provinces){ 9 }

    before do
      select('Provincial', from:'agencies_select')
    end

    it "should present a dropbox with the 9 provinces" do
      expect(page).to have_selector('select#provinces_select')
      expect(page.all('select#provinces_select option').count).to eq number_of_provinces + 1
    end

    describe "select one of the provinces" do
      let(:selected_province){ Province.all.sort_by(&:name).first } # Eastern Cape
      let(:number_of_provincial_agencies){ selected_province.provincial_agencies.count }

      before do
        select(selected_province.name, from: 'provinces_select')
      end

      it 'should show a dropdown box for the provincial agencies' do
        expect(page).to have_selector('select#eastern_cape')
        expect(number_of_provincial_agencies).to be > 0 # make sure we actually have some!
        expect(page.all('select#eastern_cape option').count).to eq number_of_provincial_agencies + 1
      end

      describe "select one of the provincial agencies" do
        let(:selected_provincial_agency){ selected_province.provincial_agencies.first }

        it "should add the selected provincial agency to the complaint" do
          select(selected_provincial_agency.name, from: 'eastern_cape')
          edit_save
          expect(complaint.agency_ids).to eq [selected_provincial_agency.id]
          expect(page.find('#agencies').text).to eq selected_provincial_agency.description
          edit_complaint
          expect( page.find('#provinces_select option', text: selected_province.name)).to be_selected
          expect( page.find('option', text: selected_provincial_agency.name)).to be_selected
        end
      end
    end
  end

  describe "select a local agency or metropolitan municipality" do
    let(:number_of_provinces){ 9 }

    before do
      select('Local', from:'agencies_select')
    end

    it "should present a dropbox with the 9 provinces" do
      expect(page).to have_selector('select#provinces_select')
      expect(page.all('select#provinces_select option').count).to eq number_of_provinces + 1
    end

    describe "select one of the provinces" do
      let(:selected_province){ Province.all.sort_by(&:name).first } # Eastern Cape
      let(:number_of_municipalities){ selected_province.municipalities.count } # includes district and metropolitan

      before do
        select(selected_province.name, from: 'provinces_select')
      end

      it 'should show a dropdown box for the provincial agencies' do
        expect(page).to have_selector('select#eastern_cape')
        expect(number_of_municipalities).to be > 0 # make sure we actually have some!
        expect(page.all('select#eastern_cape option').count).to eq number_of_municipalities + 1
      end

      describe "select a metropolitan municipality" do
        let(:selected_metro){ selected_province.metropolitan_municipalities.first }

        before do
          select(selected_metro.name, from: 'eastern_cape' )
        end

        it "should add the selected metropolitan municipality to the complaint" do
          edit_save
          expect(complaint.agency_ids).to eq [selected_metro.id]
          expect(page.find('#agencies').text).to eq selected_metro.description
        end
      end

      describe "select a local municipality" do
        let(:selected_district_municipality){ selected_province.district_municipalities.first }
        let(:dropdown_id){ selected_district_municipality.name.gsub(/\s/,'_').downcase }
        let(:selected_local_municipality){ selected_district_municipality.local_municipalities.first }
        let(:selected_local_muni_name){ selected_local_municipality.name }

        before do
          select(selected_district_municipality.name, from: 'eastern_cape' )
        end

        it "should add the selected local municipality to the complaint" do
          select(selected_local_muni_name, from: dropdown_id)
          edit_save
          expect(complaint.agency_ids).to eq [selected_local_municipality.id]
          expect(page.find('#agencies').text).to eq selected_local_municipality.description
        end
      end
    end
  end
end

feature "agency select: menu intialization", js: true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include ComplaintsSpecSetupHelpers
  include ComplaintsSpecHelpers

  let(:complaint){ IndividualComplaint.first }

  before do
    populate_database(:individual_complaint)
    complaint.update(agency_ids: [agency.id])
    visit complaint_path(:en, complaint.id)
    edit_complaint
  end

  describe "complaint is against a national government agency" do
    let(:agency){ NationalGovernmentAgency.first }

    it "should present dropboxes with the appropriate options selected" do
      expect(page.find('#agencies_select option', text: 'National')).to be_selected
      expect(page.find('#national_agencies_select option', text: 'National government agencies')).to be_selected
      expect(page.find('#government_agencies_select option', text: agency.name)).to be_selected
    end
  end

  describe "complaint is against a national government institution" do
    let(:agency){ NationalGovernmentInstitution.first }

    it "should present dropboxes with the appropriate options selected" do
      expect(page.find('#agencies_select option', text: 'National')).to be_selected
      expect(page.find('#national_agencies_select option', text: 'National government institutions')).to be_selected
      expect(page.find('#government_agencies_select option', text: agency.name)).to be_selected
    end
  end

  describe "complaint is against a democracy institution" do
    let(:agency){ DemocracySupportingStateInstitution.first }

    it "should present dropboxes with the appropriate options selected" do
      expect(page.find('#agencies_select option', text: 'National')).to be_selected
      expect(page.find('#national_agencies_select option', text:  'Democracy-supporting government institutions')).to be_selected
      expect(page.find('#government_agencies_select option', text: agency.name)).to be_selected
    end
  end

  describe "complaint is against a provincial agency" do
    let(:agency){ ProvincialAgency.first }

    it "should present dropboxes with the appropriate options selected" do
      expect(page.find('#agencies_select option', text: 'Provincial')).to be_selected
      expect(page.find('#provinces_select option', text: agency.province.name)).to be_selected
      expect(page.find("##{agency.province.name.gsub(/\s/,'_').downcase} option", text: agency.name)).to be_selected
    end
  end

  describe "complaint is against a metropolitan municipality" do
    let(:agency){ MetropolitanMunicipality.first }

    it "should present dropboxes with the appropriate options selected" do
      expect(page.find('#agencies_select option', text: 'Local')).to be_selected
      expect(page.find('#provinces_select option', text: agency.province.name)).to be_selected
      expect(page.find("##{agency.province.name.gsub(/\s/,'_').downcase} option", text: agency.name)).to be_selected
    end
  end

  describe "complaint is against a local municipality" do
    let(:agency){ LocalMunicipality.first }
    let(:province_name){ agency.district_municipality.province.name }
    let(:province_key){ province_name.gsub(/\s/,'_').downcase }
    let(:district_name){ agency.district_municipality.name }
    let(:district_key){ district_name.gsub(/\s/,'_').downcase }

    it "should present dropboxes with the appropriate options selected" do
      expect(page.find('#agencies_select option', text: 'Local')).to be_selected
      expect(page.find('#provinces_select option', text: province_name)).to be_selected
      expect(page.find("##{province_key} option", text: district_name)).to be_selected
      expect(page.find("##{district_key} option", text: agency.name)).to be_selected
    end
  end
end

feature "agency select: cancel after editing", js: true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include ComplaintsSpecSetupHelpers
  include ComplaintsSpecHelpers

  let(:complaint){ IndividualComplaint.first }

  before do
    populate_database(:individual_complaint)
    complaint.update(agency_ids: [agency.id])
    visit complaint_path(:en, complaint.id)
    edit_complaint
  end

  describe "when complaint is against a national government agency" do
    let(:agency){ NationalGovernmentAgency.first }
    let(:selected_province){ Province.all.sort_by(&:name).first } # Eastern Cape
    let(:selected_provincial_agency){ selected_province.provincial_agencies.first }

    it "should restore original agency when editing is cancelled" do
      # make edits
      select('Provincial', from:'agencies_select')
      select(selected_province.name, from: 'provinces_select')
      select(selected_provincial_agency.name, from: 'eastern_cape')
      edit_cancel
      # edits discarded
      expect(page.find('#agencies').text).to eq agency.description
      edit_complaint
      # shows original values pre edited values
      expect(page.find('#agencies_select option', text: 'National')).to be_selected
      expect(page.find('#national_agencies_select option', text: 'National government agencies')).to be_selected
      expect(page.find('#government_agencies_select option', text: agency.name)).to be_selected
    end
  end

  describe "when complaint is against a local municipality" do
    let(:agency){ LocalMunicipality.first }
    let(:selected_province){ selected_district_municipality.province }
    let(:selected_province_key){ selected_province.name.downcase.gsub(/\s/,'_') }
    let(:selected_district_municipality){ agency.district_municipality }
    let(:selected_district_key){ selected_district_municipality.name.downcase.gsub(/\s/,'_') }

    it "should restore original agency when editing is cancelled" do
      # make edits
      select('Provincial', from:'agencies_select')
      edit_cancel
      # edits discarded
      expect(page.find('#agencies').text).to eq agency.description
      edit_complaint
      # shows original values pre edited values
      expect(page.find('#agencies_select option', text: 'Local')).to be_selected
      expect(page.find('#provinces_select option', text: selected_province.name)).to be_selected
      expect(page.find("##{selected_province_key} option", text: selected_district_municipality.name )).to be_selected
      expect(page.find("##{selected_district_key} option", text: agency.name )).to be_selected
    end
  end
end

feature "select box cascade", js: true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include ComplaintsSpecSetupHelpers
  include ComplaintsSpecHelpers

  let(:complaint){ IndividualComplaint.first }

  before do
    populate_database(:individual_complaint)
    complaint.update(agency_ids: [agency.id])
    visit complaint_path(:en, complaint.id)
    edit_complaint
  end

  describe "when selected agency is a national government agency" do
    let(:agency){ NationalGovernmentAgency.first }

    describe "edit high-order select_box resets low-order menus" do
      it "should reset later low-order menus" do
        select('Provincial', from:'agencies_select')
        expect(page.find('#provinces_select option', text: 'select province...')).to be_selected
        expect(page).not_to have_selector('.tertiary.show')
        expect(page).not_to have_selector('.quarternary.show')
      end
    end

    describe "edit secondary select box resets lower order menus" do
      it "should reset later low-order menus" do
        select('National government institutions', from: 'national_agencies_select')
        expect(page.find('#government_agencies_select option', text: 'select government institution...')).to be_selected
      end
    end
  end

  describe "when selected agency is a national government institution" do
    # name: Civilian Secretariat for Police
    let(:agency){ NationalGovernmentInstitution.first }

    describe "edit high-order select_box resets low-order menus" do
      it "should reset later low-order menus" do
        select('Provincial', from:'agencies_select')
        expect(page.find('#provinces_select option', text: 'select province...')).to be_selected
        expect(page).not_to have_selector('.tertiary.show')
        expect(page).not_to have_selector('.quarternary.show')
      end
    end

    describe "edit secondary select box resets lower order menus" do
      it "should reset later low-order menus" do
        select('National government agencies', from: 'national_agencies_select')
        expect(page.find('#government_agencies_select option', text: 'select national government agency...')).to be_selected
      end
    end
  end

  describe "when selected agency is a democracy supporting government institution" do
    let(:agency){ DemocracySupportingStateInstitution.first }

    describe "edit high-order select_box resets low-order menus" do
      it "should reset later low-order menus" do
        select('Provincial', from:'agencies_select')
        expect(page.find('#provinces_select option', text: 'select province...')).to be_selected
        expect(page).not_to have_selector('.tertiary.show')
        expect(page).not_to have_selector('.quarternary.show')
      end
    end

    describe "edit secondary select box resets lower order menus" do
      it "should reset later low-order menus" do
        select('National government agencies', from: 'national_agencies_select')
        expect(page.find('#government_agencies_select option', text: 'select national government agency...')).to be_selected
      end
    end
  end

  describe "when selected agency is a provincial agency" do
    # Western Cape, Agriculture
    let(:agency){ ProvincialAgency.first }

    describe "edit high-order select_box resets low-order menus" do
      it "should reset later low-order menus" do
        select('Local', from:'agencies_select')
        expect(page.find('#provinces_select option', text: 'select province...')).to be_selected
        expect(page).not_to have_selector('.tertiary.show')
      end
    end

    describe "edit secondary select box resets lower order menus" do
      it "should reset later low-order menus" do
        select('Eastern Cape', from: 'provinces_select')
        expect(page.find('#eastern_cape option', text: 'select provincial agency...')).to be_selected
      end
    end
  end

  describe "when selected agency is a metropolitan municipality" do
    # Buffalo City, Eastern Cape
    let(:agency){ MetropolitanMunicipality.first }

    describe "edit high-order select_box resets low-order menus" do
      it "should reset later low-order menus" do
        select('Provincial', from:'agencies_select')
        expect(page.find('#provinces_select option', text: 'select province...')).to be_selected
        expect(page).not_to have_selector('.tertiary.show')
        expect(page).not_to have_selector('.quarternary.show')
      end
    end

    describe "edit secondary select box resets lower order menus" do
      it "should reset later low-order menus" do
        select('Western Cape', from: 'provinces_select')
        expect(page.find('#western_cape option', text: 'select district/metropolitan municipality...')).to be_selected
      end
    end
  end

  describe "when selected agency is a local municipality" do
    # province: Northern Cape, district_municipality: ZF Mgcawu, local_municipality: !Kheis
    let(:agency){ LocalMunicipality.first }


    describe "edit high-order select_box resets low-order menus" do
      it "should reset later low-order menus" do
        select('Provincial', from:'agencies_select')
        expect(page.find('#provinces_select option', text: 'select province...')).to be_selected
        expect(page).not_to have_selector('.tertiary.show')
        expect(page).not_to have_selector('.quarternary.show')
      end
    end

    describe "edit secondary select box resets lower order menus" do
      it "should reset later low-order menus" do
        select('Gauteng', from: 'provinces_select')
        expect(page.find('#gauteng option', text: 'select district/metropolitan municipality...')).to be_selected
        expect(page).not_to have_selector('.quarternary.show')
      end
    end

    describe "edit tertiary select box resets lower order menus" do
      it "should reset later low-order menus" do
        select('Namakwa', from: 'northern_cape');
        expect(page.find('#namakwa option', text: 'select local agency...')).to be_selected
      end
    end
  end
end

feature "add a multiple agencies", js: true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include ComplaintsSpecSetupHelpers
  include ComplaintsSpecHelpers

  let(:complaint){ IndividualComplaint.first }
  let(:first_agency){ complaint.agencies.first }
  let(:nga){ NationalGovernmentAgency.first }
  let(:ngi){ NationalGovernmentInstitution.first }
  let(:dssi){ DemocracySupportingStateInstitution.first }
  let(:pa){ ProvincialAgency.first }
  let(:lm){ LocalMunicipality.first }
  let(:mm){ MetropolitanMunicipality.first }

  let(:agencies){ [nga, ngi, pa, dssi, lm, mm] }

  before do
    populate_database(:individual_complaint, agency_count: 1)
    visit complaint_path(:en, complaint.id)
    edit_complaint
  end

  describe "add agency button" do
    it "triggers another agency select box hierarchy" do
      expect(page).to have_selector('#agencies_select', count: 1)
      agencies.each do |agency|
        page.find('#add_agency').click
        within page.all('.agency_select_container').last do
          descend_selection_hierarchy_to(agency)
        end
      end
      edit_save
      expect(page.all('#agencies .agency').map(&:text)).to match_array [first_agency.description, nga.description, ngi.description, dssi.description, pa.description, lm.description, mm.description]
    end
  end
end
