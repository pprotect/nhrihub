namespace :agencies do
  desc "import district municipalities from csv file"
  task :import_district_municipalities => :environment do
    DistrictMunicipality.destroy_all
    MetropolitanMunicipality.destroy_all
    # source is https://en.wikipedia.org/wiki/List_of_municipalities_in_South_Africa
    file = Rails.root.join('lib', 'data', 'district municipalities.csv')
    table = CSV.parse(File.read(file), headers: true)
    provinces = Province.all
    table.each do |dm|
      #headers are "Name", "Code", "Province"
      province = Province.select{|p| p.name == dm["Province"]}.first
      if (name = dm["Name"])=~/District/
        name = name.split(' ')[0...-2].join(' ')
        DistrictMunicipality.create(name: dm["Name"], province_id: province.id, code: dm["Code"])
      else
        name = name.split(' ')[0...-2].join(' ')
        MetropolitanMunicipality.create(name: name, province_id: province.id, code: dm["Code"])
      end
    end
  end
end
