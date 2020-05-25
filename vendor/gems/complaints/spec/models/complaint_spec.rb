require 'rails_helper'
require_relative '../../../authengine/spec/helpers/user_setup_helper'
require 'complaints_spec_setup_helpers'

describe "complaint" do
  context "create" do
    before do
      @complaint = IndividualComplaint.create({:status_changes_attributes => [{:complaint_status_id => nil}]})
    end

    it "should create a status_change and link to 'Registered' complaint status" do
      expect(@complaint.status_changes.length).to eq 1
      expect(@complaint.complaint_statuses.length).to eq 1
      expect(@complaint.complaint_statuses.first.name).to eq "Registered"
      expect(@complaint.current_event_description).to eq "Registered"
    end

    it "should create a complaint with unassigned agency when none is specified" do
      expect(@complaint.agencies.first.name).to eq "Unassigned"
    end
  end

  context "update status" do
    before do
      complaint_status = ComplaintStatus.find_or_create_by(name: "Assessment")
      @complaint = IndividualComplaint.create({:status_changes_attributes => [{:complaint_status_id => nil}]})
      @complaint.update({:status_changes_attributes => [{:complaint_status_id => complaint_status.id }]})
    end

    it "should create a status change object and link to the Assessment complaint status" do
      expect(@complaint.status_changes.length).to eq 2
      expect(@complaint.complaint_statuses.map(&:name)).to match_array [ "Registered", "Assessment"]
    end
  end

  context "update Complaint with no status change" do
    before do
      complaint_status = ComplaintStatus.find_or_create_by(name: "Assessment")
      @complaint = IndividualComplaint.create({:status_changes_attributes => [{:complaint_status_id => nil}]})
      @complaint.update({:status_changes_attributes => [{:complaint_status_id => complaint_status.id}]})
      @complaint.update({:status_changes_attributes => [{:complaint_status_id => complaint_status.id}]})
    end

    it "should create a status change object and link to the Active complaint status" do
      expect(@complaint.status_changes.length).to eq 2
      expect(@complaint.complaint_statuses.map(&:name)).to eq [ "Registered", "Assessment"]
    end
  end
end

describe "Complaint with gg complaint basis" do
  before do
    @complaint = IndividualComplaint.create
    @good_governance_area = ComplaintArea.create(name: "Good Governance")
    good_governance_subarea = ComplaintSubarea.create(name: "A thing", area_id: @good_governance_area.id)

    @complaint.complaint_area = @good_governance_area
    @complaint.complaint_subareas << good_governance_subarea
    @complaint.save
  end

  it "should be saved with the associations" do
    expect(@complaint.complaint_subareas.where(area_id: @good_governance_area.id).first.name).to eq "A thing"
    expect(ComplaintArea.count).to eq 1
    expect(ComplaintSubarea.count).to eq 1
  end
end

describe "server assignment of case reference" do
  let(:formatted_case_reference) { ->(year,sequence){ CaseReferenceFormat%{year:year,sequence:sequence} } }
  let(:current_year){ Date.today.strftime('%y').to_i }

  it "should not assign case reference to a new complaint" do
    expect(IndividualComplaint.new.case_reference).to be_nil
  end

  it "should assign case reference to a saved complaint" do
    expect(IndividualComplaint.create.reload.case_reference.to_s).to eq formatted_case_reference[current_year, 1]
  end
end

describe "sort algorithm" do
  let(:formatted_case_reference) { ->(year,sequence){ CaseReferenceFormat%{year:year,sequence:sequence} } }
  let(:current_year){ Date.today.strftime('%y').to_i }

  before do
    c = Complaint.create
    c.case_reference.update(year: 17, sequence: 4)
    c = Complaint.create
    c.case_reference.update(year: 16, sequence: 10)
    c = Complaint.create
    c.case_reference.update(year: 16, sequence: 2)
    c = Complaint.create
    c.case_reference.update(year: 16, sequence: 1)
    c = Complaint.create
    c.case_reference.update(year: 16, sequence: 5)
    c = Complaint.create
    c.case_reference.update(year: 15, sequence: 11)
  end

  it "should sort by ascending case reference" do
    sequenced_case_refs = [[17,4],[16,10],[16,5],[16,2],[16,1],[15,11]].map{|attrs| formatted_case_reference[ *attrs ]}
    expect(Complaint.all.sort.map(&:case_reference).map(&:to_s)).to eq sequenced_case_refs
  end
end

describe '#area_subarea_ids' do
  before do
    @complaint = FactoryBot.create(:complaint)
    @foo_area = FactoryBot.create(:complaint_area, name: 'foo')
    @bar_area = FactoryBot.create(:complaint_area, name: 'bar')
    @bish_subarea = FactoryBot.create(:complaint_subarea, area_id: @foo_area.id, name: 'bish')
    @bash_subarea = FactoryBot.create(:complaint_subarea, area_id: @foo_area.id, name: 'bash')
    @complaint.complaint_area = @foo_area
    @complaint.complaint_subareas = [@bish_subarea, @bash_subarea]
  end

  it "should create hash of area and subarea ids" do
    expect(@complaint.area_subarea_ids).to eq({ @foo_area.id => [@bish_subarea.id, @bash_subarea.id]})
  end
end

# verify that this survives performance improvements
describe "#as_json" do
  include ComplaintsSpecSetupHelpers

  context "with a full complement of associations" do
    before do
      create_agencies

      ["GoodGovernance", "Nhri", "Siu"].each do |type_prefix|
        klass = type_prefix+"::ComplaintBasis"
        klass.constantize::DefaultNames.each do |name|
          if klass.constantize.send(:where, "\"#{klass.constantize.table_name}\".\"name\"='#{name}'").length > 0
            complaint_basis = klass.constantize.send(:where, "\"#{klass.constantize.table_name}\".\"name\"='#{name}'").first
          else
            klass.constantize.create(:name => name)
          end
        end
      end

      ComplaintStatus::Names.each do |name|
        ComplaintStatus.create(:name => name)
      end

      4.times do
        FactoryBot.create(:user)
      end

      2.times do |i|
        FactoryBot.create(:complaint, :with_fixed_associations, :with_assignees, :with_document, :with_comm, :with_reminders, :with_two_notes, :case_reference => CaseReference.new(year: 17, sequence: 3-i))
      end
    end

    it 'should create a properly formatted json object' do
      @complaints = JSON.parse(Complaint.all.sort.reverse.to_json) # sorts by case_reference in descending order
      expect(@complaints).to be_an Array
      expect(@complaints.length).to be 2
      expect(@complaints.first.keys).to match_array ["heading", "id", "case_reference", "phone", "created_at", "updated_at",
                                                     "desired_outcome", "complained_to_subject_agency", "date_received",
                                                     "imported", "email", "gender", "dob", "details",
                                                     "firstName", "lastName", "title", "occupation", "employer",
                                                     "reminders", "notes", "assigns", "current_assignee_id", "current_assignee_name",
                                                     "date", "date_of_birth", "current_status", "status_id", "attached_documents",
                                                     "timeline_events", "communications", "subarea_ids", "area_subarea_ids",
                                                     "cell_phone", "city", "complaint_area_id", "complaint_type",
                                                     "alt_id_type", "physical_address", "agency_ids", "agencies", "legislation_ids",
                                                     "postal_address", "postal_code", "preferred_means", "province_id",
                                                     "alt_id_value", "alt_id_other_type", "fax", "home_phone", "id_type",
                                                     "id_value", "organization_name", "organization_registration_number", "initiating_branch_id", "initiating_office_id"]
      expect(@complaints.first["id"]).to eq Complaint.first.id # Complaint.first sorts by id in ascending order, returns lowest id/case_ref
      expect(@complaints.first["case_reference"]).to eq Complaint.first.case_reference.to_s
      expect(@complaints.first["city"]).to eq Complaint.first.city
      expect(@complaints.first["phone"]).to eq Complaint.first.phone
      # compare millisecond values, due to different precision in each value being compared
      expect(DateTime.parse(@complaints.first["created_at"]).strftime("%s")).to eq Complaint.first.created_at.to_datetime.strftime("%s")
      expect(DateTime.parse(@complaints.first["updated_at"]).strftime("%s")).to eq Complaint.first.updated_at.to_datetime.strftime("%s")
      expect(@complaints.first["desired_outcome"]).to eq Complaint.first.desired_outcome
      expect(@complaints.first["complained_to_subject_agency"]).to eq Complaint.first.complained_to_subject_agency
      expect(DateTime.parse(@complaints.first["date_received"]).strftime("%s")).to eq Complaint.first.date_received.strftime('%s')
      expect(@complaints.first["imported"]).to eq Complaint.first.imported
      expect(@complaints.first["complaint_area_id"]).to eq Complaint.first.complaint_area_id
      expect(@complaints.first["email"]).to eq Complaint.first.email
      expect(@complaints.first["gender"]).to eq Complaint.first.gender
      expect(@complaints.first["dob"]).to eq Complaint.first.dob
      expect(@complaints.first["details"]).to eq Complaint.first.details
      expect(@complaints.first["firstName"]).to eq Complaint.first.firstName
      expect(@complaints.first["lastName"]).to eq Complaint.first.lastName
      expect(@complaints.first["title"]).to eq Complaint.first.title
      expect(@complaints.first["occupation"]).to eq Complaint.first.occupation
      expect(@complaints.first["employer"]).to eq Complaint.first.employer
      expect(@complaints.first["current_assignee_id"]).to eq Complaint.first.current_assignee_id
      expect(@complaints.first["current_assignee_name"]).to eq Complaint.first.current_assignee_name
      expect(@complaints.first["date"]).to eq Complaint.first.date
      expect(@complaints.first["date_of_birth"]).to eq Complaint.first.date_of_birth
      expect(@complaints.first["status_id"]).to eq Complaint.first.status_id
      expect(@complaints.first["reminders"].first.keys).to match_array ["id", "text", "reminder_type", "remindable_id", "remindable_type", "start_date", "next", "user_id", "recipient", "next_date", "previous_date", "url", "start_year", "start_month", "start_day"]
      expect(@complaints.first["reminders"].first["recipient"].keys).to match_array ["id", "first_last_name"]
      expect(@complaints.first["notes"].first.keys).to match_array ["author_id", "author_name", "created_at", "date", "editor_id", "editor_name", "id", "notable_id", "notable_type", "text", "updated_at", "updated_on", "url"]
      expect(@complaints.first["notes"].first["author_name"]).to eq Complaint.first.notes.first.author_name
      expect(@complaints.first["notes"].first["editor_name"]).to eq Complaint.first.notes.first.editor_name
      url = Rails.application.routes.url_helpers.complaint_note_path(:en,@complaints.first["id"],@complaints.first["notes"].first["id"])
      expect(@complaints.first["notes"].first["url"]).to eq url
      expect(@complaints.first["notes"].first["updated_on"]).to eq Complaint.first.notes.first.updated_on
      expect(@complaints.first["notes"].first["date"]).to eq Complaint.first.notes.first.date
      expect(@complaints.first["assigns"].first.keys).to match_array ["date", "user_name", "event_description", "event_label"]
      expect(@complaints.first["assigns"].first["date"].to_date).to eq Complaint.first.assigns.first.date.to_date
      expect(@complaints.first["assigns"].first["event_description"]).to eq Complaint.first.assigns.first.assignee.first_last_name
      expect(@complaints.first["attached_documents"].first.keys).to match_array ["complaint_id", "original_filename", "filesize", "id", "lastModifiedDate", "original_type", "serialization_key", "title", "url", "user_id"]
      expect(@complaints.first["attached_documents"].first["url"]).to eq Complaint.first.attached_documents.first.url
      expect(@complaints.first["subarea_ids"]).to be_an Array
      expect(@complaints.first["complaint_area_id"]).to eq Complaint.first.complaint_area_id
      expect(@complaints.first["area_subarea_ids"]).to be_an Hash
      expect(@complaints.first["current_assignee_id"]).to eq Complaint.first.current_assignee_id
      expect(@complaints.first["timeline_events"].first.keys).to match_array ["date", "event_description", "user_name", "change_date", "complaint_status_id", "event_label", "status_memo", "status_memo_type"]
      expect(DateTime.parse(@complaints.first["timeline_events"].first["date"]).strftime("%s")).to eq Complaint.first.status_changes.first.date.to_datetime.strftime("%s")
      expect(@complaints.first["timeline_events"].first["event_description"]).to eq Complaint.first.status_changes.first.event_description
      expect(@complaints.first["timeline_events"].first["user_name"]).to eq Complaint.first.status_changes.first.user_name
      expect(@complaints.first["communications"].first.keys).to match_array ["attached_documents", "communicants", "complaint_id", "date", "formatted_date", "direction", "id", "mode", "note", "user", "user_id"]
      expect(@complaints.first["communications"].first["attached_documents"].first.keys ).to match_array ["communication_id", "original_filename", "filesize", "id", "lastModifiedDate", "original_type", "title", "user_id"]
      expect(@complaints.first["communications"].first["communicants"].first.keys).to match_array ["address", "email", "id", "name", "organization_id", "phone", "title_key"]
    end
  end

  context "with empty associations" do
    before do
      2.times do |i|
        c = FactoryBot.create(:complaint)
        c.case_reference.update(year: 17, sequence: 3-i)
      end
    end

    it 'should create a properly formatted json object' do
      @complaints = JSON.parse(Complaint.all.to_json)
      expect(@complaints).to be_an Array
      expect(@complaints.length).to be 2
      expect(@complaints.first.keys).to match_array ["heading", "id", "case_reference", "phone", "created_at", "updated_at",
                                                     "desired_outcome", "complained_to_subject_agency", "date_received",
                                                     "imported", "email", "gender", "dob", "details",
                                                     "firstName", "lastName", "title", "occupation", "employer",
                                                     "reminders", "notes", "assigns", "current_assignee_id", "current_assignee_name",
                                                     "date", "date_of_birth", "current_status", "status_id", "attached_documents",
                                                     "timeline_events", "communications", "subarea_ids", "area_subarea_ids",
                                                     "cell_phone", "city", "complaint_area_id", "complaint_type",
                                                     "alt_id_type", "physical_address", "agency_ids", "agencies", "legislation_ids",
                                                     "postal_address", "postal_code", "preferred_means", "province_id",
                                                     "alt_id_value", "alt_id_other_type", "fax", "home_phone", "id_type",
                                                     "id_value", "organization_name", "organization_registration_number", "initiating_branch_id", "initiating_office_id"]
      expect(@complaints.first["reminders"]).to be_empty
      expect(@complaints.first["notes"]).to be_empty
      expect(@complaints.first["assigns"]).to be_empty
      expect(@complaints.first["attached_documents"]).to be_empty
      expect(@complaints.first["subarea_ids"]).to be_empty
      expect(@complaints.first["complaint_area_id"]).to be_nil
      expect(@complaints.first["area_subarea_ids"]).to be_empty
      expect(@complaints.first["timeline_events"]).to be_empty
      expect(@complaints.first["communications"]).to be_empty
    end
  end
end

describe "duplicate complaints" do
  describe "simplest case, single bilateral duplication" do
    before do
      @complaint = FactoryBot.create(:complaint) 
      @dupe_complaint = FactoryBot.create(:complaint, dupe_refs: [@complaint.case_reference.to_s])
    end

    it "should create a bilateral duplication link" do
      expect(@dupe_complaint.reload.duplicates.map(&:id)).to eq [@complaint.id]
      expect(@complaint.reload.duplicates.map(&:id)).to eq [@dupe_complaint.id]
      expect(DuplicationGroup.count).to eq 1
    end
  end

  describe "user mis-types the case ref to link as duplicate" do
    before do
      @complaint = FactoryBot.create(:complaint) 
      @second_complaint = FactoryBot.create(:complaint)
    end

    it "should create a bilateral duplication link" do
      expect{ @complaint.dupe_refs= ["abcd"] }.to raise_exception(ArgumentError)
    end
  end

  describe "user types non-existent case ref" do
    before do
      @complaint = FactoryBot.create(:complaint) 
      @second_complaint = FactoryBot.create(:complaint)
    end

    it "should create a bilateral duplication link" do
      expect{ @complaint.dupe_refs= ["7/2-00200/20"] }.to raise_exception(ActiveRecord::RecordNotFound)
    end
  end

  describe "two dupe_refs supplied, which are not previously linked" do
    # all three become linked
    before do
      @complaint = FactoryBot.create(:complaint) 
      @second_complaint = FactoryBot.create(:complaint)
      @third_complaint = FactoryBot.create(:complaint)
      @complaint.dupe_refs=[@second_complaint.case_reference.to_s, @third_complaint.case_reference.to_s]
    end

    it "should create a trilateral duplication link" do
      expect(@complaint.reload.duplicates.map(&:id)).to match_array [@second_complaint.id, @third_complaint.id]
      expect(@second_complaint.reload.duplicates.map(&:id)).to match_array [@complaint.id, @third_complaint.id]
      expect(@third_complaint.reload.duplicates.map(&:id)).to match_array [@second_complaint.id, @complaint.id]
      expect(DuplicationGroup.count).to eq 1
    end
  end

  describe "single dupe ref supplied, and it's already in a group" do
    # join the existing group
    before do
      @complaint = FactoryBot.create(:complaint) 
      @second_complaint = FactoryBot.create(:complaint)
      @third_complaint = FactoryBot.create(:complaint)
      @second_complaint.dupe_refs=[@third_complaint.case_reference.to_s]
      @complaint.dupe_refs=[@second_complaint.case_reference.to_s]
    end

    it "should create a trilateral duplication link" do
      expect(@complaint.reload.duplicates.map(&:id)).to match_array [@second_complaint.id, @third_complaint.id]
      expect(@second_complaint.reload.duplicates.map(&:id)).to match_array [@complaint.id, @third_complaint.id]
      expect(@third_complaint.reload.duplicates.map(&:id)).to match_array [@second_complaint.id, @complaint.id]
      expect(DuplicationGroup.count).to eq 1
    end
  end

  describe "two dupe refs supplied, and they're in different groups" do
    # coalesce the two groups and end up with a single group with three complaints
    before do
      @complaint = FactoryBot.create(:complaint) 
      @second_complaint = FactoryBot.create(:complaint)
      @third_complaint = FactoryBot.create(:complaint)
      @fourth_complaint = FactoryBot.create(:complaint)
      @fifth_complaint = FactoryBot.create(:complaint)
      @second_complaint.dupe_refs=[@third_complaint.case_reference.to_s]
      @fourth_complaint.dupe_refs=[@fifth_complaint.case_reference.to_s]
      @complaint.dupe_refs=[@second_complaint.case_reference.to_s, @fourth_complaint.case_reference.to_s]
    end

    it "should create a trilateral duplication link" do
      expect(@complaint.reload.duplicates.map(&:id)).to match_array [@second_complaint.id, @third_complaint.id, @fourth_complaint.id, @fifth_complaint.id]
      expect(@second_complaint.reload.duplicates.map(&:id)).to match_array [@complaint.id, @third_complaint.id, @fourth_complaint.id, @fifth_complaint.id]
      expect(@third_complaint.reload.duplicates.map(&:id)).to match_array [@complaint.id, @second_complaint.id, @fourth_complaint.id, @fifth_complaint.id]
      expect(@fourth_complaint.reload.duplicates.map(&:id)).to match_array [@complaint.id, @second_complaint.id, @third_complaint.id, @fifth_complaint.id]
      expect(@fifth_complaint.reload.duplicates.map(&:id)).to match_array [@complaint.id, @second_complaint.id, @third_complaint.id, @fourth_complaint.id]
      expect(DuplicationGroup.count).to eq 1
    end
  end

  describe "complaint is already in a duplication group, and it's designated as a dupe of another" do
    # all three complaints are in the resulting group
    before do
      @complaint = FactoryBot.create(:complaint) 
      @second_complaint = FactoryBot.create(:complaint, dupe_refs: [@complaint.case_reference.to_s])
      @third_complaint = FactoryBot.create(:complaint)
      @fourth_complaint = FactoryBot.create(:complaint, dupe_refs: [@third_complaint.case_reference.to_s])
      @complaint.reload.dupe_refs=[@third_complaint.case_reference.to_s]
    end

    it "should dissolve existing group and add to new group" do
      expect(@complaint.reload.duplicates.map(&:id)).to match_array [@third_complaint.id, @fourth_complaint.id]
      expect(DuplicationGroup.count).to eq 1
      expect(@second_complaint.reload.duplication_group_id).to be_nil
    end
  end

  describe "complaint is already in a duplication group, and it's designated as a dupe of another, second scenario" do
    # all three complaints are in the resulting group
    before do
      # first group
      @complaint = FactoryBot.create(:complaint) 
      @another_complaint = FactoryBot.create(:complaint)
      @second_complaint = FactoryBot.create(:complaint, dupe_refs: [@complaint.case_reference.to_s, @another_complaint.case_reference.to_s])

      # second group
      @third_complaint = FactoryBot.create(:complaint)
      @fourth_complaint = FactoryBot.create(:complaint, dupe_refs: [@third_complaint.case_reference.to_s])

      @complaint.dupe_refs=[@third_complaint.case_reference.to_s]
    end

    it "should dissolve existing group and add to new group" do
      expect(@complaint.reload.duplicates.map(&:id)).to match_array [@third_complaint.id, @fourth_complaint.id]
      expect(@second_complaint.duplicates.map(&:id)).to eq [@another_complaint.id]
      expect(DuplicationGroup.count).to eq 2
    end
  end

end
