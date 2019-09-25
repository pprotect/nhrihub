require 'rails_helper'
require_relative '../../../authengine/spec/helpers/user_setup_helper'
require_relative '../helpers/complaints_spec_setup_helpers'

describe "scope class methods" do
  include UserSetupHelper
  include ComplaintsSpecSetupHelpers

  let(:open){ ComplaintStatus.where(:name => 'Open').first.id }
  let(:closed){ ComplaintStatus.where(:name => 'Closed').first.id }
  let(:under_evaluation){ ComplaintStatus.where(:name => 'Under Evaluation').first.id }


  describe "query by current assignee" do
    before do
      @user = create_user('admin')
      @staff_user = create_user('staff')
      FactoryBot.create(:complaint, :assigned_to => [@user, @staff_user])
      FactoryBot.create(:complaint, :assigned_to => [@staff_user, @user])
    end

    it "returns complaints based on assignee" do
      #expect(Complaint.for_assignee(@user.id)).to eq Complaint.all.select{|c| c.current_assignee_id == @user.id}
      expect(Complaint.for_assignee(@staff_user.id)).to eq Complaint.all.select{|c| c.current_assignee_id == @staff_user.id}
      #expect(Complaint.for_assignee).to be_empty
    end
  end

  describe "query by current status" do
    before do
      FactoryBot.create(:complaint, :open)
      FactoryBot.create(:complaint, :closed)
      FactoryBot.create(:complaint, :under_evaluation)
    end

    it "returns complaints with current requested status" do
      expect(Complaint.with_status(open)).to eq Complaint.all.select{|c| c.current_status == 'Open'}
      expect(Complaint.with_status(closed)).to eq Complaint.all.select{|c| c.current_status == 'Closed'}
      expect(Complaint.with_status(under_evaluation)).to eq Complaint.all.select{|c| c.current_status == 'Under Evaluation'}
    end
  end

  describe "query by current status and current assignee" do
    before do
      @user = create_user('admin')
      @staff_user = create_user('staff')
      FactoryBot.create(:complaint, :open, :assigned_to => [@user, @staff_user])
      FactoryBot.create(:complaint, :closed, :assigned_to => [@user, @staff_user])
      FactoryBot.create(:complaint, :open, :assigned_to => [@staff_user, @user])
      FactoryBot.create(:complaint, :closed, :assigned_to => [@staff_user, @user])
    end

    it "should merge the two scopes" do
      expect(Complaint.with_status(open).for_assignee(@user.id).length).to eq 1
    end
  end

  describe "query by date_received" do
    before do
      user = FactoryBot.create(:user)
      FactoryBot.create(:complaint, :open, assigned_to: user, date_received: 1.month.ago)
      FactoryBot.create(:complaint, :open, assigned_to: user, date_received: 1.month.ago.end_of_day)
      FactoryBot.create(:complaint, :open, assigned_to: user, date_received: 1.month.ago.beginning_of_day)

      FactoryBot.create(:complaint, :open, assigned_to: user, date_received: 2.months.ago)
      FactoryBot.create(:complaint, :open, assigned_to: user, date_received: 2.months.ago.end_of_day)
      FactoryBot.create(:complaint, :open, assigned_to: user, date_received: 2.months.ago.beginning_of_day)

      FactoryBot.create(:complaint, :open, assigned_to: user, date_received: 3.months.ago)
      FactoryBot.create(:complaint, :open, assigned_to: user, date_received: 3.months.ago.end_of_day)
      FactoryBot.create(:complaint, :open, assigned_to: user, date_received: 3.months.ago.beginning_of_day)

      FactoryBot.create(:complaint, :open, assigned_to: user, date_received: 4.months.ago)
      FactoryBot.create(:complaint, :open, assigned_to: user, date_received: 4.months.ago.end_of_day)
      FactoryBot.create(:complaint, :open, assigned_to: user, date_received: 4.months.ago.beginning_of_day)
    end

    it "returns complaints before the 'to' date" do
      date_string = Date.today.advance(months: -3).strftime("%Y, %b %d")
      expect(Complaint.before_date(date_string).count).to eq 6
    end

    it "returns complaints since the 'from' date" do
      date_string = Date.today.advance(months: -3).strftime("%Y, %b %d")
      expect(Complaint.since_date(date_string).count).to eq 9
    end
  end

  describe "query by complaint_basis" do
    let(:gg_area_id){ComplaintArea.find_or_create_by(:name => "Good Governance").id}
    let(:gg_subarea_ids){ ComplaintSubarea.where(:area_id => gg_area_id).pluck(:id) }
    let(:siu_area_id){ComplaintArea.find_or_create_by(:name => "Special Investigations Unit").id}
    let(:siu_subarea_ids){ ComplaintSubarea.where(:area_id => siu_area_id).pluck(:id) }
    let(:user){ FactoryBot.create(:user) }
    let(:mandate){ Mandate.first }
    let(:ids){ Complaint.pluck(:id) }
    let(:query){
      {:selected_assignee_id=>user.id,
       :selected_status_ids=>ComplaintStatus.pluck(:id),
       :selected_mandate_ids=>Mandate.pluck(:id),
       :selected_agency_ids => Agency.pluck(:id),
       :selected_area_ids => ComplaintArea.pluck(:id),
       :selected_subarea_ids => ComplaintSubarea.pluck(:id)
      }
    }
    let(:complaints){ Complaint.index_page_associations(Complaint.pluck(:id), query) }

    before do
      create_mandates
      create_agencies
      populate_areas_subareas
      complaint_area = ComplaintArea.first
      complaint_subarea = ComplaintSubarea.where(area_id: complaint_area.id).first
      FactoryBot.create(:complaint,
                        :open,
                        assigned_to: user,
                        mandate_id: mandate.id,
                        agencies: [Agency.first],
                        complaint_areas: [complaint_area],
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

    it "should return single matching complaints when combined with with_mandates scope" do
      compound_scope = Complaint.
                         with_subareas(siu_subarea_ids + gg_subarea_ids).
                         with_mandates([mandate.id]).
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
     :selected_mandate_ids=>Mandate.pluck(:id),
     :selected_agency_ids=>Agency.pluck(:id),
     :selected_subarea_ids => [foo_subarea.id, bar_subarea.id] }
  }
  let(:complaints){ Complaint.index_page_associations(Complaint.pluck(:id), query) }
  let(:area){ FactoryBot.create(:complaint_area) }
  let(:foo_subarea) { FactoryBot.create(:complaint_subarea, area_id: area.id, name: 'foo')}
  let(:bar_subarea)  { FactoryBot.create(:complaint_subarea, area_id: area.id, name: 'bar')}
  let(:baz_subarea)  { FactoryBot.create(:complaint_subarea, area_id: area.id, name: 'baz')}

  before do
    create_agencies
    create_mandates
    mandate_id = Mandate.first.id
    @foo_complaint = FactoryBot.create(:complaint, :open, agencies: [Agency.first], mandate_id: mandate_id, complaint_subareas: [foo_subarea], assigned_to: user)
    @bar_complaint = FactoryBot.create(:complaint,:open, agencies: [Agency.first], mandate_id: mandate_id, complaint_subareas: [bar_subarea],  assigned_to: user)
    @baz_complaint = FactoryBot.create(:complaint, :open, agencies: [Agency.first], mandate_id: mandate_id, complaint_subareas: [baz_subarea],  assigned_to: user)
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
