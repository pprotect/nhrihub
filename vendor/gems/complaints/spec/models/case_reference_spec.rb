require 'rails_helper'

describe "CaseReference in the current year"  do
  before do
    year = Date.today.strftime("%y").to_i
    sequence = 18
    @case_reference = CaseReference.new(year,sequence)
  end

  it "should produce a value for the next reference in the current year" do
    expect(@case_reference.next_ref.year).to eq Date.today.strftime("%y").to_i
    expect(@case_reference.next_ref.sequence).to eq 19
    expect(@case_reference.next_ref.to_s).to eq "C#{Date.today.strftime("%y")}-19"
  end
end

describe "CaseReference in the previous year"  do
  before do
    year = Date.today.strftime("%y").to_i - 1
    sequence = 18
    @case_reference = CaseReference.new(year,sequence)
  end

  it "should produce a value for the next reference in the current year" do
    expect(@case_reference.next_ref.year).to eq Date.today.strftime("%y").to_i
    expect(@case_reference.next_ref.sequence).to eq 1
    expect(@case_reference.next_ref.to_s).to eq "C#{Date.today.strftime("%y")}-1"
  end
end

describe "CaseReference comparing values" do
  before do
    @list = [
      CaseReference.new(16,15),
      CaseReference.new(16,1),
      CaseReference.new(17,10),
      CaseReference.new(17,1)
    ]
  end

  it "should sort by year and sequence, most-recent-first" do
    expect(@list.sort.map(&:to_s)).to eq ["C17-10","C17-1","C16-15","C16-1"]
  end

  it "should calculate the next value" do
    expect(CaseReference.new(17,10).next_ref.year).to eq Date.today.strftime("%y").to_i
    expect(CaseReference.new(17,10).next_ref.sequence).to eq 1
  end
end

describe "CaseReferenceCollection" do
  before do
    cr1 = CaseReference.new(16,15)
    cr2 = CaseReference.new(16,1)
    @cr3 = CaseReference.new(17,10)
    cr4 = CaseReference.new(17,1)
    @collection = CaseReferenceCollection.new [cr1,cr2,@cr3,cr4]
  end

  it "should select the highest reference" do
    expect(@collection.highest_ref).to eq @cr3
  end

  it "should generate the next reference" do
    expect(@collection.next_ref).to be_a CaseReference
    expect(@collection.next_ref.year).to eq Date.today.strftime("%y").to_i
    expect(@collection.next_ref.sequence).to eq 1
  end
end

describe "CaseReference.sql_matchj" do
  let(:complaint){ FactoryBot.create(:complaint) }

  it "should disregard nil fragment" do
    complaint.update_attribute(:case_reference, CaseReference.new(19,1234))
    case_ref_fragment = nil
    expect(Complaint.with_case_reference_match(case_ref_fragment)).to eq [complaint]
  end

  it "should disregard blank string fragment" do
    complaint.update_attribute(:case_reference, CaseReference.new(19,1234))
    case_ref_fragment = ""
    expect(Complaint.with_case_reference_match(case_ref_fragment)).to eq [complaint]
  end

  it "should match single digit" do
    complaint.update_attribute(:case_reference, CaseReference.new(19,1234))
    case_ref_fragment = "1"
    expect(Complaint.with_case_reference_match(case_ref_fragment)).to eq [complaint]
  end

  it "should match two digits" do
    complaint.update_attribute(:case_reference, CaseReference.new(19,1234))
    case_ref_fragment = "19"
    expect(Complaint.with_case_reference_match(case_ref_fragment)).to eq [complaint]
  end

  it "should match three digits" do
    complaint.update_attribute(:case_reference, CaseReference.new(19,1234))
    case_ref_fragment = "191"
    expect(Complaint.with_case_reference_match(case_ref_fragment)).to eq [complaint]
  end

  it "should match four digits" do
    complaint.update_attribute(:case_reference, CaseReference.new(19,1234))
    case_ref_fragment = "1912"
    expect(Complaint.with_case_reference_match(case_ref_fragment)).to eq [complaint]
  end

  it "should match all digits" do
    complaint.update_attribute(:case_reference, CaseReference.new(19,1234))
    case_ref_fragment = "191234"
    expect(Complaint.with_case_reference_match(case_ref_fragment)).to eq [complaint]
  end

  it "should match all digits with arbitrary alpha interspersed" do
    complaint.update_attribute(:case_reference, CaseReference.new(19,1234))
    case_ref_fragment = "f1a9 b1c 23d4x"
    expect(Complaint.with_case_reference_match(case_ref_fragment)).to eq [complaint]
  end

  it "should not match if extra digits are appended" do
    complaint.update_attribute(:case_reference, CaseReference.new(19,1234))
    case_ref_fragment = "1912345"
    expect(Complaint.with_case_reference_match(case_ref_fragment)).to be_empty
  end

  it "should not match if any digits do not match" do
    complaint.update_attribute(:case_reference, CaseReference.new(19,1234))
    case_ref_fragment = "291234"
    expect(Complaint.with_case_reference_match(case_ref_fragment)).to be_empty
  end
end

describe "unique case reference generation" do
  subject! do
    class TestModel < ActiveRecord::Base
      after_commit :generate_case_reference, on: :create
      serialize :case_reference, CaseReference

      def generate_case_reference
        update_column :case_reference, TestModel.next_case_reference
      end

      def self.next_case_reference
        case_references = CaseReferenceCollection.new(all.pluck(:case_reference))
        case_references.next_ref
      end
    end
  end

  before do
    connection = ActiveRecord::Base.connection
    connection.create_table :test_models do |t|
      t.string :case_reference
    end
    connection.add_index :test_models, :case_reference, unique: true
  end

  after do
    connection = ActiveRecord::Base.connection
    connection.commit_transaction
    if connection.table_exists? :test_models
      connection.drop_table :test_models
    end
  end

  it "should save and fetch CaseReferences" do
    tm = TestModel.create
    expect(tm.reload.case_reference).to be_a CaseReference
    expect(tm.case_reference.to_s).to eq "C#{Date.today.strftime("%y")}-1"
    tm = TestModel.create
    expect(tm.case_reference.to_s).to eq "C#{Date.today.strftime("%y")}-2"
  end

  it "should raise argument error if two test models are saved with the same case reference" do
    # simulate simultaneous saving of two Complaints, each thinks the highest ref is 19,1
    allow_any_instance_of(CaseReferenceCollection).to receive(:highest_ref).and_return(CaseReference.new(19,1))
    tm1 = TestModel.create
    expect(tm1.case_reference.to_s).to eq "C19-2"
    expect{ TestModel.create }.to raise_error ActiveRecord::RecordNotUnique
  end

end
