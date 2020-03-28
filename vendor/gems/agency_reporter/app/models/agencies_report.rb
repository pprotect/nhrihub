class AgenciesReport < WordReport
  Root = AgencyReporter::Engine.root
  TMP_DIR = Rails.root.join('tmp', 'agencies')
  TEMPLATE_PATH = 'app/views/agency_reporter'
  SourceDoc = 'agencies_list.docx' # it's the source for genaterating the template. See report_utilities/report_template.rb
  attr_accessor :agencies, :agency_template

  def initialize(agencies)
    @agencies = agencies
    super()
  end

  def generate_word_doc
    tail_template = File.read(self.class::Root.join(self.class::TEMPLATE_PATH, "_tail.xml"))
    @agency_template = File.read(self.class::Root.join(self.class::TEMPLATE_PATH, "_tree_item_template.xml"))
    list = interpolate_list(agencies, agency_template,0)
    @word_doc = head + list + tail_template
    generate_header
  end

  def generate_header
    header_template = self.class::Root.join(self.class::TEMPLATE_PATH, "docx", "word", "header1.xml")
    header_file = self.class::TMP_DIR.join('docx', 'word', "header1.xml")
    IO.write(header_file, File.open(header_template) do |f|
      interpolate(f.read, { :print_date => Date.today } )
    end)
  end

  def head
    head_template = File.read(self.class::Root.join(self.class::TEMPLATE_PATH, "_head.xml"))
    interpolate(head_template, { :query_string => "foo", :print_date => Date.today  })
  end

  def interpolate_list(list,template,level)
    list.map { |item| interpolate(template, item, level) }.join
  end

  def interpolate(template,object,level=nil)
    object = object.stringify_keys if object.respond_to?(:stringify_keys)
    interpolated_template = template.gsub(/\{\{\s*list_level_index\s*\}\}/, level.to_s)
    interpolated_template = interpolated_template.gsub(/\{\{\s*(\w*)\s*\}\}/) { ERB::Util.html_escape(object[$1].to_s) }
    if object.is_a?(Hash) && object.key?("collection") && !object["collection"].nil?
      interpolated_template + interpolate_list(object["collection"],@agency_template,level+1)
    else
      interpolated_template
    end
  end
end
