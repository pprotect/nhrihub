require 'rails_helper'

describe "CaseReference in the current year"  do
  before do
    @case_reference = CaseReference.new("C#{Date.today.strftime("%y")}-18")
  end

  it "should produce a value for the next reference in the current year" do
    expect(@case_reference.next_ref).to eq "C#{Date.today.strftime("%y")}-19"
  end
end

describe "CaseReference in the previous year"  do
  before do
    @case_reference = CaseReference.new("C#{Date.today.strftime("%y").to_i-1}-18")
  end

  it "should produce a value for the next reference in the current year" do
    expect(@case_reference.next_ref).to eq "C#{Date.today.strftime("%y")}-1"
  end
end

describe "CaseReference comparing values" do
  before do
    @list = [
      CaseReference.new("C16-15"),
      CaseReference.new("C16-1"),
      CaseReference.new("C17-10"),
      CaseReference.new("C17-1")
    ]
  end

  it "should sort by year and sequence, most-recent-first" do
    expect(@list.sort.map(&:ref)).to eq ["C17-10","C17-1","C16-15","C16-1"]
  end

  it "should calculate the next value" do
    if Date.today.year == 2017
      next_ref = "C17-11"
    else
      next_ref = "C#{Date.today.strftime("%y")}-1"
    end
    expect(CaseReference.new("C17-10").next_ref).to eq next_ref
  end
end

describe "CaseReferenceCollection" do
  before do
    @collection = CaseReferenceCollection.new [ "C16-15", "C16-1", "C17-10", "C17-1" ]
  end

  it "should select the highest reference" do
    expect(@collection.highest_ref.ref).to eq "C17-10"
  end

  it "should generate the next reference" do
    if Date.today.year == 2017
      next_ref = "C17-11"
    else
      next_ref = "C#{Date.today.strftime("%y")}-1"
    end
    expect(@collection.next_ref).to eq next_ref
  end
end

describe "CaseReference.sql_match" do
  let(:null_ref){ '1=1' }
  it "should disregard nil fragment" do
    expect(CaseReference.sql_match(nil)).to eq null_ref
  end

  it "should disregard blank string fragment" do
    expect(CaseReference.sql_match("")).to eq null_ref
  end

  it "should construct sql query from digit strings of any length" do
    year = "21"
    sequence = "98764493215518124512343"
    expect(CaseReference.sql_match(year+sequence)).to eq "complaints.case_reference ~* '^C#{year}-*#{sequence}'"
  end

  it "should construct sql query from very short digit strings" do
    year = "2"
    expect(CaseReference.sql_match(year)).to eq "complaints.case_reference ~* '^C#{year}-*'"
    year = "19"
    expect(CaseReference.sql_match(year)).to eq "complaints.case_reference ~* '^C#{year}-*'"
    year = "19"
    sequence = "3"
    expect(CaseReference.sql_match(year+sequence)).to eq "complaints.case_reference ~* '^C#{year}-*#{sequence}'"
  end
end
