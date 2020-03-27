require 'builder'

class Excess::Rels
  attr_accessor :relationships
  BASIC_RELATIONSHIPS = [
                         {:id=>"rId1", :type=>"http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet", :target=>"worksheets/sheet1.xml"},
                         {:id=>"rId2", :type=>"http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme", :target=>"theme/theme1.xml"},
                         {:id=>"rId3", :type=>"http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles", :target=>"styles.xml"},
                         {:id=>"rId4", :type=>"http://schemas.openxmlformats.org/officeDocument/2006/relationships/sharedStrings", :target=>"sharedStrings.xml"}
                        ]


  def initialize
    @relationships = BASIC_RELATIONSHIPS.dup
  end

  def render_to_string
    xml = Builder::XmlMarkup.new
    xml.instruct! :xml, :standalone => 'yes'
      xml.Relationships "xmlns" => "http://schemas.openxmlformats.org/package/2006/relationships" do
        @relationships.each do |rel|
          xml.Relationship "Id" => rel[:id], "Type" => rel[:type], "Target" => rel[:target]
        end
      end
  end

  def create_file
    FileUtils.makedirs(Rails.application.root.join('tmp/xlsx/xl/_rels'))
    File.open(Rails.application.root.join('tmp/xlsx/xl/_rels/workbook.xml.rels'), File::RDWR|File::TRUNC|File::CREAT){|f| f.write(render_to_string)}
  end
end
