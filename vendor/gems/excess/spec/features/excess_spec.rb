require 'rails_helper'

feature "dummy application" do
  scenario "should exist" do
    expect(Rails.application).to be_kind_of Dummy::Application
  end
end

feature "xlsx request sends an Excel spreadsheet as a file", :type => :feature do
  before do
    visit "/test.html"
    click_link "Excel document"
  end

  scenario "contains appropriate headers" do
    headers = page.response_headers
    expect(headers['Content-Type']).to include "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    expect(headers['Content-Disposition']).to include 'attachment; filename="test_doc.xlsx"'
    expect(headers['Content-Transfer-Encoding']).to eq 'binary'
  end
end

feature "xlsx mime type" do
  scenario "should be registered" do
    expect(Mime::Type.lookup_by_extension("xlsx").to_sym).to eq :xlsx
    expect(Mime::Type.lookup_by_extension("xlsx").to_s).to eq "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
  end
end

feature "Excess::Spreadsheet instance methods" do
  feature "#create_template method" do
    scenario "creates a blank document filesystem in the tmp directory" do
      Excess::Spreadsheet.new({}).create_template
      ["_rels","docProps","xl","xl/_rels","xl/theme","xl/worksheets"].each do |path|
        dir = Rails.application.root.join('tmp','xlsx',path)
        expect(File.exists?(dir)).to be true
        expect(File.directory?(dir)).to be true
      end
      ["docProps/app.xml","docProps/core.xml","xl/_rels/workbook.xml.rels","xl/theme/theme1.xml","xl/styles.xml","xl/workbook.xml","[Content_Types].xml"].each do |path|
        file = Rails.application.root.join('tmp','xlsx',path)
        expect(File.exists?(file)).to be true
        expect(File.file?(file)).to be true
      end
    end
  end

  feature "#cleanup method" do
    scenario "removes xlsx directory from /tmp" do
      doc = Excess::Spreadsheet.new({})
      doc.create_template
      expect(File.exists?(Rails.application.root.join("tmp/xlsx"))).to be true
      doc.cleanup(Rails.application.root.join("tmp/xlsx"))
      expect(File.exists?(Rails.application.root.join("tmp/xlsx"))).to be false
    end
  end

  feature "#zip_package method" do
    after do
      @doc.cleanup(@doc.tmp_file)
    end

    scenario "creates a file with the passed-in filename in the tmp directory" do
      @doc = Excess::Spreadsheet.new({})
      @doc.create_template
      @doc.zip_package(Rails.application.root.join("tmp/xlsx"))
      expect(File.exists?(Rails.application.root.join("tmp/tmp_file.xlsx"))).to be true
    end
  end

  feature "#contents method" do
    after do
      @doc.cleanup(Rails.root.join('tmp','xlsx'))
    end

    scenario "creates the document.xml file in the document filesystem" do
      @doc = Excess::Spreadsheet.new({})
      @doc.create_template
      contents = "<bish><bash><bosh>Kablooie</bosh></bash></bish>"
      @doc.contents contents
      expect(File.exists?(Rails.application.root.join("tmp/xlsx/xl/worksheets/sheet1.xml"))).to be true
      expect(File.read(Rails.application.root.join("tmp/xlsx/xl/worksheets/sheet1.xml"))).to eq contents
    end
  end

end

feature "Excess::Rels" do
  feature "after initialization" do
    scenario "should have a relationships property, which is an array of hashes of target, type and id values" do
      rel = Excess::Rels.new
      expect(rel.relationships).to be_kind_of(Array)
      expect(rel.relationships.size).to eq 4
      rel.relationships.each do |r|
        expect(r).to be_kind_of(Hash)
        expect(r.has_key?(:target)).to be true
        expect(r.has_key?(:type)).to be true
        expect(r.has_key?(:id)).to be true
      end
    end
  end

  #feature "next_id method" do
    #it "should add a relationship as specified in the argument, with the next id in sequence" do
      #rel = Excess::Rels.new
      #rel.next_id(:printer).should eq "rId6"
      #rel.relationships.size.should eq 6
    #end
  #end

  feature "render_to_string method" do
    scenario "should create a string of rels file xml contents" do
      rel = Excess::Rels.new
      string = <<-REL
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme" Target="theme/theme1.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
  <Relationship Id="rId4" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/sharedStrings" Target="sharedStrings.xml"/>
</Relationships>
      REL
      expect(rel.render_to_string).to eq string.gsub(/\n(\s+)?/,'') # the result has whitespace removed!
    end
  end

  feature "create_file method" do
    scenario "should create a file in the document filesystem called document.xml.rels" do
      rel = Excess::Rels.new
      rel.create_file
      expect(File.exists?(Rails.application.root.join('tmp/xlsx/xl/_rels/workbook.xml.rels'))).to be true
    end
  end
end
