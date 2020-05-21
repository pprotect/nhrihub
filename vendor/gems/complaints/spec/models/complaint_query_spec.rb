require 'rails_helper'
require_relative '../../../authengine/spec/helpers/user_setup_helper'
require_relative '../helpers/complaints_spec_setup_helpers'

describe "scope class methods" do
  include UserSetupHelper
  include ComplaintsSpecSetupHelpers

  let(:registered){ ComplaintStatus.find_or_create_by(:name => 'Registered').id }
  let(:closed){ ComplaintStatus.find_or_create_by(:name => 'Closed').id }
  let(:assessment){ ComplaintStatus.find_or_create_by(:name => 'Assessment').id }


  describe "query by current assignee" do
    before do
      @user = create_user('admin')
      @staff_user = create_user('staff')
      FactoryBot.create(:complaint, :assigned_to => [@user, @staff_user])
      FactoryBot.create(:complaint, :assigned_to => [@staff_user, @user])
    end

    it "returns complaints based on assignee" do
      expect(Complaint.for_assignee(@user.id)).to eq Complaint.all.select{|c| c.current_assignee_id == @user.id}
      expect(Complaint.for_assignee(@staff_user.id)).to eq Complaint.all.select{|c| c.current_assignee_id == @staff_user.id}
      expect(Complaint.for_assignee.length).to eq 2
    end
  end

  describe "query by current status" do
    before do
      FactoryBot.create(:complaint, :registered)
      FactoryBot.create(:complaint, :closed)
      FactoryBot.create(:complaint, :assessment)
    end

    it "returns complaints with current requested status" do
      expect(Complaint.with_status(registered)).to eq Complaint.all.select{|c| c.current_status.complaint_status.name == 'Registered'}
      expect(Complaint.with_status(closed)).to eq Complaint.all.select{|c| c.current_status.complaint_status.name == 'Closed'}
      expect(Complaint.with_status(assessment)).to eq Complaint.all.select{|c| c.current_status.complaint_status.name == 'Assessment'}
    end
  end

  describe "query by current status and current assignee" do
    before do
      @user = create_user('admin')
      @staff_user = create_user('staff')
      FactoryBot.create(:complaint, :registered, :assigned_to => [@user, @staff_user])
      FactoryBot.create(:complaint, :closed, :assigned_to => [@user, @staff_user])
      FactoryBot.create(:complaint, :registered, :assigned_to => [@staff_user, @user])
      FactoryBot.create(:complaint, :closed, :assigned_to => [@staff_user, @user])
    end

    it "should merge the two scopes" do
      expect(Complaint.with_status(registered).for_assignee(@user.id).length).to eq 1
    end

    it "should merge the two scopes when there are no matches" do
      expect(Complaint.with_status(assessment).for_assignee(@user.id).length).to eq 0
    end
  end

  describe "query by date_received" do
    before do
      user = FactoryBot.create(:user)
      FactoryBot.create(:complaint, :registered, assigned_to: user, date_received: 1.month.ago)
      FactoryBot.create(:complaint, :registered, assigned_to: user, date_received: 1.month.ago.end_of_day)
      FactoryBot.create(:complaint, :registered, assigned_to: user, date_received: 1.month.ago.beginning_of_day)

      FactoryBot.create(:complaint, :registered, assigned_to: user, date_received: 2.months.ago)
      FactoryBot.create(:complaint, :registered, assigned_to: user, date_received: 2.months.ago.end_of_day)
      FactoryBot.create(:complaint, :registered, assigned_to: user, date_received: 2.months.ago.beginning_of_day)

      FactoryBot.create(:complaint, :registered, assigned_to: user, date_received: 3.months.ago)
      FactoryBot.create(:complaint, :registered, assigned_to: user, date_received: 3.months.ago.end_of_day)
      FactoryBot.create(:complaint, :registered, assigned_to: user, date_received: 3.months.ago.beginning_of_day)

      FactoryBot.create(:complaint, :registered, assigned_to: user, date_received: 4.months.ago)
      FactoryBot.create(:complaint, :registered, assigned_to: user, date_received: 4.months.ago.end_of_day)
      FactoryBot.create(:complaint, :registered, assigned_to: user, date_received: 4.months.ago.beginning_of_day)
    end

    it "returns complaints before the 'to' date" do
      date_string = Time.zone.now.advance(months: -3).strftime("%Y, %b %d")
      expect(Complaint.before_date(date_string).count).to eq 6
    end

    it "returns complaints since the 'from' date" do
      date_string = Time.zone.now.advance(months: -3).strftime("%Y, %b %d")
      expect(Complaint.since_date(date_string).count).to eq 9
    end
  end

  describe "query by complaint_subareas" do
    let(:gg_area_id){ComplaintArea.find_or_create_by(:name => "Good Governance").id}
    let(:gg_subarea_ids){ ComplaintSubarea.where(:area_id => gg_area_id).pluck(:id) }
    let(:siu_area_id){ComplaintArea.find_or_create_by(:name => "Special Investigations Unit").id}
    let(:siu_subarea_ids){ ComplaintSubarea.where(:area_id => siu_area_id).pluck(:id) }
    let(:user){ FactoryBot.create(:user) }
    let(:complaint_area){ ComplaintArea.first }
    let(:ids){ Complaint.pluck(:id) }
    let(:query){
      {:selected_assignee_id=>user.id,
       :selected_status_ids=>ComplaintStatus.pluck(:id),
       :selected_complaint_area_ids=>ComplaintArea.pluck(:id),
       :selected_agency_id => "all",
       :selected_area_ids => ComplaintArea.pluck(:id),
       :selected_subarea_ids => ComplaintSubarea.pluck(:id)
      }
    }
    let(:complaints){ Complaint.index_page_associations(query) }

    before do
      create_complaint_areas
      create_agencies
      populate_areas_subareas
      complaint_area = ComplaintArea.first
      complaint_subarea = ComplaintSubarea.where(area_id: complaint_area.id).first
      FactoryBot.create(:complaint,
                        :registered,
                        assigned_to: user,
                        complaint_area_id: complaint_area.id,
                        agencies: [Agency.first],
                        complaint_subareas: [complaint_subarea] )
    end

    it "should return unique matching complaints" do
      expect(Complaint.with_subareas( gg_subarea_ids + siu_subarea_ids ).distinct.count).to eq 1
    end

    it "should return unique matching complaints when combined with for_assignee scope" do
      compound_scope = Complaint.for_assignee(user.id).
                                 with_subareas(siu_subarea_ids + gg_subarea_ids).
                                 length
      expect(compound_scope).to eq 1
    end

    it "should return single matching complaints when combined with with_complaint_areas scope" do
      compound_scope = Complaint.
                         with_subareas(siu_subarea_ids + gg_subarea_ids).
                         where(complaint_area_id: complaint_area.id).
                         distinct.
                         count
      expect(compound_scope).to eq 1
    end

    it "should execute full index query with all scopes" do
      expect(complaints.length).to eq 1
    end
  end
end

describe "selects complaints matching the selected subarea" do
  include ComplaintsSpecSetupHelpers

  let(:user){ FactoryBot.create(:user) }
  let(:query){
    {:selected_assignee_id=>user.id,
     :selected_status_ids=>ComplaintStatus.pluck(:id),
     :selected_complaint_area_ids=>ComplaintArea.pluck(:id),
     :selected_agency_id=>"all",
     :selected_subarea_ids => [foo_subarea.id, bar_subarea.id] }
  }
  let(:complaints){ Complaint.index_page_associations(query) }
  let(:area){ FactoryBot.create(:complaint_area) }
  let(:foo_subarea) { FactoryBot.create(:complaint_subarea, area_id: area.id, name: 'foo')}
  let(:bar_subarea)  { FactoryBot.create(:complaint_subarea, area_id: area.id, name: 'bar')}
  let(:baz_subarea)  { FactoryBot.create(:complaint_subarea, area_id: area.id, name: 'baz')}

  before do
    create_agencies
    create_complaint_areas
    complaint_area_id = ComplaintArea.first.id
    @foo_complaint = FactoryBot.create(:complaint, :registered, agencies: [Agency.first], complaint_area_id: complaint_area_id, complaint_subareas: [foo_subarea], assigned_to: user)
    @bar_complaint = FactoryBot.create(:complaint,:registered, agencies: [Agency.first], complaint_area_id: complaint_area_id, complaint_subareas: [bar_subarea],  assigned_to: user)
    @baz_complaint = FactoryBot.create(:complaint, :registered, agencies: [Agency.first], complaint_area_id: complaint_area_id, complaint_subareas: [baz_subarea],  assigned_to: user)
  end

  it "should return complaints with subareas indicated by the query" do
    expect(complaints).to match_array [@foo_complaint, @bar_complaint]
  end

  it "should return complaints with subareas requested by the query" do
    query[:selected_subarea_ids] = ComplaintSubarea.pluck(:id)
    expect(complaints).to match_array [@foo_complaint, @bar_complaint, @baz_complaint]
  end

  it "should return complaints with subareas requested by the query" do
    query[:selected_subarea_ids] = []
    expect(complaints).to eq []
  end
end

describe "selects complaints matching the selected agency (complaint list filter scenario)" do
  include ComplaintsSpecSetupHelpers

  let(:user){ FactoryBot.create(:user) }
  let(:query){
    {:selected_assignee_id=>user.id,
     :selected_status_ids=>ComplaintStatus.pluck(:id),
     :selected_complaint_area_ids=>ComplaintArea.pluck(:id),
     :selected_agency_id=>"all",
     :selected_subarea_ids => [foo_subarea.id, bar_subarea.id] }
  }
  let(:complaints){ Complaint.index_page_associations(query) }
  let(:unassigned_agency) { Agency.unscoped.where(name: "Unassigned").first }

  before do
    create_agencies
    create_complaint_areas
    complaint_area_id = ComplaintArea.first.id
    @foo_complaint = FactoryBot.create(:complaint, :registered, assigned_to: user)
    @bar_complaint = FactoryBot.create(:complaint, :registered, agencies: [Agency.first], assigned_to: user)
  end

  it "should return complaints with matching agency assignment" do
    expect(Complaint.with_agencies([Agency.first.id])).to eq [ @bar_complaint ]
  end

  it "should assign the 'Unassigned' agency to the complaint for which no agency was specified" do
    expect(@foo_complaint.agency_ids).to include unassigned_agency.id
    expect(Complaint.with_agencies([unassigned_agency.id])).to eq [ @foo_complaint ]
  end
end

describe "selects complaints matching any of the supplied agency ids (complaint duplicate search scenario)" do
  include ComplaintsSpecSetupHelpers

  let(:complaints){ DuplicateComplaint.with_any_agencies_matching(agencies) }
  let(:first_agency){ Agency.limit(1).offset(0).first }
  let(:second_agency){ Agency.limit(1).offset(1).first }
  let(:third_agency){ Agency.limit(1).offset(2).first }

  before do
    create_agencies
    @foo_complaint = FactoryBot.create(:complaint, agencies: [first_agency])
    @bar_complaint = FactoryBot.create(:organization_complaint, agencies: [first_agency, second_agency])
    @baz_complaint = FactoryBot.create(:complaint, agencies: [third_agency])
  end

  it "should return all complaints matching any of the passed-in ids" do
    agencies = [first_agency.id]
    complaints= Complaint.with_any_agencies_matching(agencies)
    expect(complaints).to match_array [@foo_complaint.becomes(DuplicateComplaint), @bar_complaint.becomes(DuplicateComplaint)]
    expect(complaints.map(&:class).map(&:name)).to match_array ['DuplicateComplaint', 'DuplicateComplaint']
  end

  it "should return all complaints matching any of the passed-in ids" do
    agencies = [second_agency.id, third_agency.id]
    complaints= Complaint.with_any_agencies_matching(agencies) 
    expect(complaints).to match_array [@baz_complaint.becomes(DuplicateComplaint), @bar_complaint.becomes(DuplicateComplaint)]
  end

  it "should return no complaints if request ids array is empty" do
    complaints= Complaint.with_any_agencies_matching([]) 
    expect(complaints).to be_empty
  end

  it "should return no complaints if request ids array contains blank string" do
    complaints= Complaint.with_any_agencies_matching([""]) 
    expect(complaints).to be_empty
  end
end

describe "selects complaints with home- cell- or fax-number matching" do
  before do
    @complaint1 = FactoryBot.create(:complaint, home_phone: "(541) 888-3311", cell_phone: "303 869 8832", fax: "332-1881")
    @complaint2 = FactoryBot.create(:complaint, home_phone: "(323) 143-9873", cell_phone: "182 889 1324", fax: "(303) 484 8672")
    @complaint3 = FactoryBot.create(:complaint, home_phone: "183-2387", cell_phone: "(398) 181 3327", fax: "432 1841")
  end

  it "should match any of the phone numbers against the filter criterion" do
    expect(Complaint.with_phone("8").map(&:id)).to eq [@complaint1, @complaint2, @complaint3].map(&:id)
    expect(Complaint.with_phone("88").map(&:id)).to eq [@complaint1, @complaint2].map(&:id)
    expect(Complaint.with_phone("883").map(&:id)).to eq [@complaint1].map(&:id)
    expect(Complaint.with_phone("32").map(&:id)).to eq [@complaint1, @complaint2, @complaint3].map(&:id)
    expect(Complaint.with_phone("321").map(&:id)).to eq [@complaint1, @complaint3].map(&:id)
    expect(Complaint.with_phone("034").map(&:id)).to eq [@complaint2].map(&:id)
  end
end

describe "#with_case_reference_match" do
  context "single digit entry" do
    before do
      @complaint1 = FactoryBot.create(:complaint)
      @complaint2 = FactoryBot.create(:complaint)
      @complaint3 = FactoryBot.create(:complaint)
    end

    it "match case reference digits" do
      expect(Complaint.with_case_reference_match("3").first).to eq @complaint3
    end
  end

  context "disregards user-entered zeros" do
    before do
      @complaint1 = FactoryBot.create(:complaint)
      @complaint2 = FactoryBot.create(:complaint)
      @complaint3 = FactoryBot.create(:complaint)
    end

    it "match case reference digits" do
      expect(Complaint.with_case_reference_match("00003").first).to eq @complaint3
    end
  end

  context "multiple digit entry" do
    before do
      15.times do
        FactoryBot.create(:complaint)
      end
    end

    it "matches only the starting digit pattern" do
      expect(Complaint.with_case_reference_match("5").count).to eq 1
      expect(Complaint.with_case_reference_match("52").count).to eq 1
      expect(Complaint.with_case_reference_match("520").count).to eq 1
    end
  end
end

describe "#for_assignee" do
  let(:user){ FactoryBot.create(:user) }
  let(:assigned_complaint){ FactoryBot.create(:complaint, assigned_to: user) }
  let(:unassigned_complaint){ FactoryBot.create(:complaint) }

  it "returns no results if assignee_id is nil" do
    expect(Complaint.for_assignee(nil)).to be_empty
  end

  it "returns no results if assignee_id is blank" do
    expect(Complaint.for_assignee(nil)).to be_empty
  end

  it "matches assigned_complaint when assignee.id is specified" do
    expect(Complaint.for_assignee(user.id)).to eq [assigned_complaint]
  end

  it "matches unassigned_complaint when assignee.id is 0" do
    expect(Complaint.for_assignee(0)).to eq [unassigned_complaint]
  end
end

describe "#transferred_to" do
  let(:gauteng){ Province.find_or_create_by(name: 'Gauteng') }
  let(:gauteng_office){ Office.create(province_id: gauteng.id) }
  let!(:gauteng_complaint){ FactoryBot.create(:complaint, transferred_to: gauteng_office ) }

  let(:limpopo){ Province.find_or_create_by(name: 'Limpopo') }
  let(:limpopo_office){ Office.create(province_id: limpopo.id) }
  let!(:limpopo_complaint){ FactoryBot.create(:complaint, transferred_to: limpopo_office ) }

  it "should return complaints transferred to the specified office" do
    expect(Complaint.transferred_to(gauteng_office.id)).to eq [gauteng_complaint]
  end
end
