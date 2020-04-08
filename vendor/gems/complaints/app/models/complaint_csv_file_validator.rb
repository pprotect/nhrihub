class ComplaintCsvFileValidator
  Columns = { 'A' =>"COMPLAINT", 'B' =>"DATE OPENED", 'C' =>"DATE ASSESSED", 'D' =>"REFERENCE NUMBER",
              'E' =>"DATE OF ALLOCATION", 'F' =>"ALLOCATED TO UNIT / PROVINCE", 'G' =>"ASSESSOR",
              'H' =>"FILE WITH INVESTIGATOR", 'I' =>"RECOMMENDATION BY ASSESSOR / TRANSFER", 'J' =>"ACT",
              'K' =>"NOT YET ALLOCATED / DUPLICATE", 'L' =>"INSTITUTION COMPLAINED AGAINST", 'M' =>"RESIDENCE",
              'N' =>"PROVINCE", 'O' =>"GENDER", 'P' =>"SUMMARY OF COMPLAINT" }

  attr_accessor :column_name, :table, :lines_analysed, :errored_records, :errors_found, :agency_names, :district_names, :regional_names

  def self.data_patterns
    ('a'..'z').inject({}){|h,alpha| h[alpha.upcase]= I18n.t("import_patterns.#{alpha}_pattern"); h}
  end
  DataPatterns = data_patterns

  def initialize(params, file_path)
    @column_name = Columns[params[:column]]
    @table = CSV.parse(File.read(file_path), headers: true)
    @agency_names = Agency.pluck(:name).map(&:downcase)
    @district_names = DistrictMunicipality.pluck(:name).map(&:downcase)
    @regional_names = Office.regional.pluck(:name)
    validate
  end

  def validate
    @lines_analysed = 0
    @errors_found = 0
    @errored_records = []
    puts "b /Users/lesnightingill/Code/ppsa/vendor/gems/complaints/app/models/complaint_csv_record_validator.rb:144 if institution=~/STUDENT FINANCIAL/"
    puts "info breakpoints"
    puts "del <breakpoint number>"
    debugger
    `:> test.txt`
    table.each do |complaint|
      validator = ComplaintCsvRecordValidator.new(complaint,column_name,complaint["REFERENCE NUMBER"],agency_names,district_names,regional_names)
      next if validator.date_separator
      @lines_analysed += 1
      unless validator.valid?
        @errored_records << validator.errors
        @errors_found += 1
      end
    end
    `sort test.txt -u -o test.txt`
  end
end
