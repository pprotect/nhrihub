require 'rails_helper'
require 'case_reference'

describe ".create" do
  context "when none exist in the database" do
    let!(:case_reference){ CaseReference.create }

    it "should start the sequence at 1" do
      expect(case_reference.year).to eq Date.today.strftime("%y").to_i # last two digits
      expect(case_reference.sequence).to eq 1
      expect(CaseReference.max).to be_a CaseReference
      expect(CaseReference.max.year).to eql 20
      expect(CaseReference.max.sequence).to eql 1
      expect(CaseReference.max.next_ref.year).to eq Date.today.strftime("%y").to_i
      expect(CaseReference.max.next_ref.sequence).to eq 2
    end
  end

  context "when there are others" do
    before do
      5.times do
        CaseReference.create
      end
    end

    it "should create sequential case references" do
      expect(CaseReference.pluck(:sequence)).to eq [1,2,3,4,5]
    end
  end
end

describe "flexible formatting defined by an application constant" do
  it "should represent case reference in Samoa-specific format" do
    stub_const("CaseReferenceFormat","C%<year>i-%<sequence>i")
    expect(CaseReference.new(year: 20, sequence: 8).to_s).to eq "C20-8"
  end

  it "should represent case reference in South Africa-specific format" do
    stub_const("CaseReferenceFormat","7/2-%05<sequence>i/%<year>i")
    expect(CaseReference.new(year: 20, sequence: 8).to_s).to eq "7/2-00008/20"
  end
end

context "Samoa formatted string" do
  let(:year){ Date.today.strftime("%y") }
  let(:sequence){ 18 }

  before do
    stub_const("CaseReferenceFormat","C%<year>i-%<sequence>i")
  end

  describe "CaseReference in the current year"  do
    before do
      @case_reference = CaseReference.new(year: year, sequence: sequence)
    end

    it "should produce a value for the next reference in the current year" do
      expect(@case_reference.next_ref.year).to eq year.to_i
      expect(@case_reference.next_ref.sequence).to eq 19
      expect(@case_reference.next_ref.to_s).to eq "C#{year}-19"
    end
  end

  describe "CaseReference in the previous year"  do
    before do
      year = year.to_i - 1
      @case_reference = CaseReference.new(year: year, sequence: sequence)
    end

    it "should produce a value for the next reference in the current year" do
      expect(@case_reference.next_ref.year).to eq year.to_i
      expect(@case_reference.next_ref.sequence).to eq 1
      expect(@case_reference.next_ref.to_s).to eq "C#{year}-1"
    end
  end

  describe "CaseReference comparing values" do
    before do
      @list = [
        CaseReference.new(year: 16, sequence: 15),
        CaseReference.new(year: 16, sequence: 1),
        CaseReference.new(year: 17, sequence: 10),
        CaseReference.new(year: 17, sequence: 1)
      ]
    end

    it "should sort by year and sequence, most-recent-first" do
      expect(@list.sort.map(&:to_s)).to eq ["C17-10","C17-1","C16-15","C16-1"]
    end

    it "should calculate the next value" do
      expect(CaseReference.new(year: 17, sequence: 10).next_ref.year).to eq year.to_i
      expect(CaseReference.new(year: 17, sequence: 10).next_ref.sequence).to eq 1
    end
  end

  describe "CaseReferenceCollection" do
    before do
      cr1 = CaseReference.new(year: 16, sequence: 15)
      cr2 = CaseReference.new(year: 16, sequence: 1)
      @cr3 = CaseReference.new(year: 17, sequence: 10)
      cr4 = CaseReference.new(year: 17, sequence: 1)
      @collection = CaseReferenceCollection.new [cr1,cr2,@cr3,cr4]
    end

    it "should select the highest reference" do
      expect(@collection.highest_ref).to eq @cr3
    end

    it "should generate the next reference" do
      expect(@collection.next_ref).to be_a CaseReference
      expect(@collection.next_ref.year).to eq year.to_i
      expect(@collection.next_ref.sequence).to eq 1
    end
  end

  describe "CaseReference.sql_match" do
    let(:complaint){ FactoryBot.create(:complaint) }
    let(:result){ ->(case_ref_fragment){ Complaint.with_case_reference_match(case_ref_fragment) } }

    before do
      complaint.case_reference.update(year: 19, sequence: 1234)
    end

    it "should disregard nil fragment" do
      case_ref_fragment = nil
      expect(result[ case_ref_fragment ]).to eq [complaint] # result is a lambda, one way it can be called is result[arg]
    end

    it "should disregard blank string fragment" do
      case_ref_fragment = ""
      expect(result[ case_ref_fragment ]).to eq [complaint]
    end

    it "should match single digit" do
      case_ref_fragment = "1"
      expect(result[ case_ref_fragment ]).to eq [complaint]
    end

    it "should match two digits" do
      case_ref_fragment = "19"
      expect(result[ case_ref_fragment ]).to eq [complaint]
    end

    it "should match three digits" do
      case_ref_fragment = "191"
      expect(result[ case_ref_fragment ]).to eq [complaint]
    end

    it "should match four digits" do
      case_ref_fragment = "1912"
      expect(result[ case_ref_fragment ]).to eq [complaint]
    end

    it "should match all digits" do
      case_ref_fragment = "191234"
      expect(result[ case_ref_fragment ]).to eq [complaint]
    end

    it "should match all digits with arbitrary alpha interspersed" do
      case_ref_fragment = "f1a9 b1c 23d4x"
      expect(result[ case_ref_fragment ]).to eq [complaint]
    end

    it "should not match if extra digits are appended" do
      case_ref_fragment = "1912345"
      expect(result[ case_ref_fragment ]).to be_empty
    end

    it "should not match if any digits do not match" do
      case_ref_fragment = "291234"
      expect(result[ case_ref_fragment ]).to be_empty
    end
  end
end

context "South Africa formatted string" do
  let(:year){ Date.today.strftime("%y") }
  let(:sequence){ 18 }

  before do
    stub_const("CaseReferenceFormat","7/2-%05<sequence>i/%<year>i")
  end

  describe "CaseReference in the current year"  do
    before do
      @case_reference = CaseReference.new(year: year, sequence: sequence)
    end

    it "should produce a value for the next reference in the current year" do
      expect(@case_reference.next_ref.year).to eq year.to_i
      expect(@case_reference.next_ref.sequence).to eq 19
      expect(@case_reference.next_ref.to_s).to eq "7/2-00019/#{year}"
    end
  end

  describe "CaseReference in the previous year"  do
    before do
      year = year.to_i - 1
      @case_reference = CaseReference.new(year: year, sequence: sequence)
    end

    it "should produce a value for the next reference in the current year" do
      expect(@case_reference.next_ref.year).to eq year.to_i
      expect(@case_reference.next_ref.sequence).to eq 1
      expect(@case_reference.next_ref.to_s).to eq "7/2-00001/20"
    end
  end

  describe "CaseReference comparing values" do
    before do
      @list = [
        CaseReference.new(year: 16, sequence: 15),
        CaseReference.new(year: 16, sequence: 1),
        CaseReference.new(year: 17, sequence: 10),
        CaseReference.new(year: 17, sequence: 1)
      ]
    end

    it "should sort by year and sequence, most-recent-first" do
      expect(@list.sort.map(&:to_s)).to eq ["7/2-00010/17", "7/2-00001/17", "7/2-00015/16", "7/2-00001/16"]
    end
  end

  describe ".parse" do
    let(:result){ CaseReference.parse(string).values_at(:year, :sequence) }
    before do
      stub_const("CaseReferenceRegex","(?:7\/2)?(?:\s{0,5})0{0,4}(?<sequence>[1-9]{1,5}[0-9]{0,5})(?:\/)?(?<year>[1-9][0-9])")
    end

    describe "when string is fully formed" do
      let(:string){ "7/2-00200/20"}
      it "extracts year and sequence disregarding fixed format elements" do
        expect(result).to eq [20,200]
      end
    end

    describe "when string is fully formed" do
      let(:string){ "7/2-00001/20"}
      it "extracts year and sequence disregarding fixed format elements" do
        expect(result).to eq [20,1]
      end
    end

    describe "when string omits fixed preamble" do
      let(:string){ "00200/20"}
      it "extracts year and sequence disregarding fixed format elements" do
        expect(result).to eq [20,200]
      end
    end

    describe "when string omits fixed preamble and sequence/year separator" do
      let(:string){ "0020020"}
      it "extracts year and sequence disregarding fixed format elements" do
        expect(result).to eq [20,200]
      end
    end

    describe "when string omits fixed preamble and sequence/year separator and has leading/trailing whitespace" do
      let(:string){ " 0020020 "}
      it "extracts year and sequence disregarding fixed format elements" do
        expect(result).to eq [20,200]
      end
    end

    describe "when string omits fixed preamble, sequence/year separator, sequence leading zeroes, and has leading/trailing whitespace" do
      let(:string){ " 20020 "}
      it "extracts year and sequence disregarding fixed format elements" do
        expect(result).to eq [20,200]
      end
    end
  end
end
