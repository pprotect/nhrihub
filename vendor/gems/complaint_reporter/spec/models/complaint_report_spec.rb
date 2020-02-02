require 'rails_helper'

feature "complaint report" do
  scenario "it should produce valid xml with weird characters in fields" do
    user = FactoryBot.create(:user)
    agency = FactoryBot.create(:agency, :name => "&&<<>>//")
    complaint = FactoryBot.create(:complaint, :details=> "&><**/", :agencies => [agency])
    complaint_report = ComplaintReport.new(complaint, user)
    report = complaint_report.generate_word_doc
    docx = File.read(ComplaintReport::TMP_DIR.join('docx', 'word', 'document.xml').to_s)
    xml_doc = Nokogiri::XML(docx)
    expect(xml_doc.errors).to be_empty
  end
end

feature "complaints report" do
  scenario "it should produce valid xml with weird characters in fields" do
    complaint = FactoryBot.build(:individual_complaint, :details=> "&><**/")
    complaint.assign_initial_status(FactoryBot.create(:user))
    complaint.save
    complaints_report = ComplaintsReport.new([complaint])
    report = complaints_report.generate_word_doc
    docx = File.read(ComplaintsReport::TMP_DIR.join('docx', 'word', 'document.xml').to_s)
    xml_doc = Nokogiri::XML(docx)
    expect(xml_doc.errors).to be_empty
  end
end

