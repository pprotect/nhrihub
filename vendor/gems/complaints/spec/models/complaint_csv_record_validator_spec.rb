require 'rails_helper'

describe 'identify_institution_by_generic_pattern' do
  let(:agency){ "SOUTH AFRICAN POLICE SERVICES" }
  let(:initials){ "SAPS" }
  let(:branch){ "BELMONT STATION" }
  let(:province_abbrev){ "NW" }
  let(:institution){ "#{agency} (#{initials}) (#{branch}) (#{province_abbrev})" }
  let(:institution_without_province){ "#{agency} (#{initials}) (#{branch})" }
  let(:institution_without_province_initials){ "#{agency} (#{branch})" }
  let(:complaint){ {"INSTITUTION COMPLAINED AGAINST" => institution} }
  let(:column_name){ "INSTITUTION COMPLAINED AGAINST" }
  let(:ref){ "anything" }
  let(:agency_names){ ["SOUTH AFRICAN POLICE SERVICES"] }
  let(:district_names){ ["bish", "bash", "bosh"] }
  let(:regional_names){ ["words", "deeds", "thoughts"] }
  let(:validator){ ComplaintCsvRecordValidator.new(complaint, column_name,ref,agency_names,district_names,regional_names) }

  it "should extract province" do
    expect(validator.send(:extract_province, institution)).to eq [institution_without_province, "North West"]
  end

  it "should extract initials" do
    expect(validator.send(:extract_initials, institution_without_province)).to eq [institution_without_province_initials, agency.titlecase, initials]
  end

  it "should declare the complaint valid" do
    expect(validator.valid?).to eq true
  end

end

describe 'identify_institution_by_generic_pattern' do
  let(:agency){ "SOUTH AFRICAN POLICE SERVICES" }
  let(:initials){ "SAPS" }
  let(:province_abbrev){ "NW" }
  let(:institution){ "#{agency} (#{initials}) (#{province_abbrev})" }
  let(:institution_without_province){ "#{agency} (#{initials})" }
  let(:institution_without_province_initials){ "#{agency}" }
  let(:complaint){ {"INSTITUTION COMPLAINED AGAINST" => institution} }
  let(:column_name){ "INSTITUTION COMPLAINED AGAINST" }
  let(:ref){ "anything" }
  let(:agency_names){ ["SOUTH AFRICAN POLICE SERVICES"] }
  let(:district_names){ ["bish", "bash", "bosh"] }
  let(:regional_names){ ["words", "deeds", "thoughts"] }
  let(:validator){ ComplaintCsvRecordValidator.new(complaint, column_name,ref,agency_names,district_names,regional_names) }

  it "should extract province" do
    expect(validator.send(:extract_province, institution)).to eq [institution_without_province, "North West"]
  end

  it "should extract initials" do
    expect(validator.send(:extract_initials, institution_without_province)).to eq [institution_without_province_initials, agency.titlecase, initials]
  end

  it "should declare the complaint valid" do
    expect(validator.valid?).to eq true
  end

end

describe 'identify_institution_by_generic_pattern' do
  let(:agency){ "DEPARTMENT OF HEALTH" }
  let(:initials){ "DOH" }
  let(:institution){ "#{agency} (#{initials}) (NW)" }
  let(:institution_without_province){ "#{agency} (#{initials})" }
  let(:institution_without_province_initials){ "#{agency}" }
  let(:column_name){ "INSTITUTION COMPLAINED AGAINST" }
  let(:complaint){ { column_name => institution} }
  let(:ref){ "anything" }
  let(:agency_names){ ["HEALTH"] }
  let(:district_names){ ["bish", "bash", "bosh"] }
  let(:regional_names){ ["words", "deeds", "thoughts"] }
  let(:validator){ ComplaintCsvRecordValidator.new(complaint, column_name,ref,agency_names,district_names,regional_names) }

  before do
  end

  it "should extract province" do
    expect(validator.send(:extract_province, institution)).to eq [institution_without_province, "North West"]
  end

  it "should extract initials" do
    expect(validator.send(:extract_initials, institution_without_province)).to eq [institution_without_province_initials, agency.titlecase, initials]
  end

  it "should declare the complaint valid" do
    expect(validator.valid?).to eq true
  end

end

describe 'identify_institution_by_generic_pattern' do
  let(:institution){ "HEALTH" }
  let(:column_name){ "INSTITUTION COMPLAINED AGAINST" }
  let(:complaint){ { column_name => institution} }
  let(:ref){ "anything" }
  let(:agency_names){ ["HEALTH"] }
  let(:district_names){ ["bish", "bash", "bosh"] }
  let(:regional_names){ ["words", "deeds", "thoughts"] }
  let(:validator){ ComplaintCsvRecordValidator.new(complaint, column_name,ref,agency_names,district_names,regional_names) }


  it "should declare the complaint valid" do
    expect(validator.valid?).to eq true
  end

end

describe 'identify_institution_by_generic_pattern' do
  let(:institution){ "SOUTH AFRICA POLICE SERVICE" }
  let(:column_name){ "INSTITUTION COMPLAINED AGAINST" }
  let(:complaint){ { column_name => institution} }
  let(:ref){ "anything" }
  let(:agency_names){ ["SOUTH AFRICAN POLICE SERVICE"] }
  let(:district_names){ ["bish", "bash", "bosh"] }
  let(:regional_names){ ["words", "deeds", "thoughts"] }
  let(:validator){ ComplaintCsvRecordValidator.new(complaint, column_name,ref,agency_names,district_names,regional_names) }

  it "should declare the complaint valid" do
    expect(validator.valid?).to eq true
  end

end

describe 'identify_institution_by_generic_pattern' do
  let(:institution){ "SOUTH AFRICAN POLICE SERVICE" }
  let(:column_name){ "INSTITUTION COMPLAINED AGAINST" }
  let(:complaint){ { column_name => institution} }
  let(:ref){ "anything" }
  let(:agency_names){ ["SOUTH AFRICAN POLICE SERVICE"] }
  let(:district_names){ ["bish", "bash", "bosh"] }
  let(:regional_names){ ["words", "deeds", "thoughts"] }
  let(:validator){ ComplaintCsvRecordValidator.new(complaint, column_name,ref,agency_names,district_names,regional_names) }

  it "should declare the complaint valid" do
    expect(validator.valid?).to eq true
  end

end

describe 'identify_institution_by_saps_pattern' do
  let(:institution){ "SAPS KIMBERLY POLICE STATION (NC)" }
  let(:column_name){ "INSTITUTION COMPLAINED AGAINST" }
  let(:complaint){ { column_name => institution} }
  let(:ref){ "anything" }
  let(:agency_names){ ["SOUTH AFRICAN POLICE SERVICE"] }
  let(:district_names){ ["bish", "bash", "bosh"] }
  let(:regional_names){ ["words", "deeds", "thoughts"] }
  let(:validator){ ComplaintCsvRecordValidator.new(complaint, column_name,ref,agency_names,district_names,regional_names) }

  it "should declare the complaint valid" do
    expect(validator.valid?).to eq true
    expect(validator.branch_information).to eq "KIMBERLY POLICE STATION"
  end
end

describe 'identify institution by parenthesized saps pattern' do
  let(:institution){ "SAPS (KIMBERLY POLICE STATION) (NC)" }
  let(:column_name){ "INSTITUTION COMPLAINED AGAINST" }
  let(:complaint){ { column_name => institution} }
  let(:ref){ "anything" }
  let(:agency_names){ ["SOUTH AFRICAN POLICE SERVICE"] }
  let(:district_names){ ["bish", "bash", "bosh"] }
  let(:regional_names){ ["words", "deeds", "thoughts"] }
  let(:validator){ ComplaintCsvRecordValidator.new(complaint, column_name,ref,agency_names,district_names,regional_names) }

  it "should declare the complaint valid" do
    expect(validator.valid?).to eq true
    expect(validator.branch_information).to eq "KIMBERLY POLICE STATION"
  end
end

describe 'identify institution by municipality' do
  let(:institution){ "RUSTERNBURG LOCAL MUNICIPALITY (NC)" }
  let(:column_name){ "INSTITUTION COMPLAINED AGAINST" }
  let(:complaint){ { column_name => institution} }
  let(:ref){ "anything" }
  let(:agency_names){ ["RUSTERNBURG"] }
  let(:district_names){ ["bish", "bash", "bosh"] }
  let(:regional_names){ ["words", "deeds", "thoughts"] }
  let(:validator){ ComplaintCsvRecordValidator.new(complaint, column_name,ref,agency_names,district_names,regional_names) }

  it "should declare the complaint valid" do
    expect(validator.valid?).to eq true
  end
end

describe 'identify institution by municipality with levenshtein non-zero value' do
  let(:institution){ "RUSTERNBRUG LOCAL MUNICIPALITY (NC)" }
  let(:column_name){ "INSTITUTION COMPLAINED AGAINST" }
  let(:complaint){ { column_name => institution} }
  let(:ref){ "anything" }
  let(:agency_names){ ["RUSTENBURG"] }
  let(:district_names){ ["bish", "bash", "bosh"] }
  let(:regional_names){ ["words", "deeds", "thoughts"] }
  let(:validator){ ComplaintCsvRecordValidator.new(complaint, column_name,ref,agency_names,district_names,regional_names) }

  it "should declare the complaint valid" do
    expect(validator.valid?).to eq true
  end
end

describe 'identify institution by municipality with levenshtein non-zero value' do
  let(:institution){ "WESTERN CAPE PROVINCIAL GOVERNMENT (WC)" }
  let(:column_name){ "INSTITUTION COMPLAINED AGAINST" }
  let(:complaint){ { column_name => institution} }
  let(:ref){ "anything" }
  let(:agency_names){ ["WESTERN CAPE"] }
  let(:district_names){ ["bish", "bash", "bosh"] }
  let(:regional_names){ ["words", "deeds", "thoughts"] }
  let(:validator){ ComplaintCsvRecordValidator.new(complaint, column_name,ref,agency_names,district_names,regional_names) }

  it "should declare the complaint valid" do
    expect(validator.valid?).to eq true
  end
end
