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
    populate_database(:individual_complaint)
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
          expect(complaint.agency_id).to eq selected_provincial_agency.id
          expect(page.find('#agencies').text).to eq selected_provincial_agency.name
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
        expect(page).to have_selector('.tertiary#eastern_cape')
        expect(number_of_municipalities).to be > 0 # make sure we actually have some!
        expect(page.all('.tertiary#eastern_cape select option').count).to eq number_of_municipalities + 1
      end

      describe "select a metropolitan municipality" do
        let(:selected_metro){ selected_province.metropolitan_municipalities.first }

        before do
          select(selected_metro.name, from: 'eastern_cape' )
        end

        it "should add the selected metropolitan municipality to the complaint" do
          edit_save
          expect(complaint.agency_id).to eq selected_metro.id
          expect(page.find('#agencies').text).to eq selected_metro.name
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
          expect(complaint.agency_id).to eq selected_local_municipality.id
          expect(page.find('#agencies').text).to eq selected_local_muni_name
        end
      end
    end
  end
end
