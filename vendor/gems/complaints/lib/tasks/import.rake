namespace :agencies do
  desc "import all"
  task :import => [ :import_district_municipalities, :import_provincial, :import_local_municipalities]

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
      province = provinces.select{|p| p.name == dm["Province"]}.first
      if (name = dm["Name"])=~/District/
        name = name.split(' ')[0...-2].join(' ').strip
        DistrictMunicipality.create(name: name, province_id: province.id, code: dm["Code"])
      else
        name = name.split(' ')[0...-2].join(' ').strip
        MetropolitanMunicipality.create(name: name, province_id: province.id, code: dm["Code"])
      end
    end
  end

  desc "import local"
  task :import_local_municipalities => :environment do
    LocalMunicipality.destroy_all
    file = Rails.root.join('lib', 'data', 'local municipalities.csv')
    table = CSV.parse(File.read(file), headers: true)
    provinces = Province.all
    districts = DistrictMunicipality.all
    table.each do |lm|
      # headers are Name,Code,Province,District,,,,
      province = provinces.select{|p| p.name == lm["Province"]}.first
      district = districts.select{|d| d.name.downcase == lm["District"]&.downcase}.first
      if (name = lm["Name"])=~/Local/
        name = name.split(' ')[0...-2].join(' ').strip
        LocalMunicipality.create(name: name, province_id: province.id, district_id: district.id, code: lm["Code"])
      end
    end
  end

  desc "import provincial agencies"
  task :import_provincial => :environment do
    LocalMunicipality.destroy_all
    ProvincialAgency.destroy_all
    file = Rails.root.join('lib', 'data', 'provincial agencies.csv')
    table = CSV.parse(File.read(file), headers: true)
    provinces = Province.all
    table.each do |pa|
      province = provinces.select{|p| p.name == pa["Province"]}.first
      ProvincialAgency.create(name: pa["Name"].strip, province_id: province.id)
    end
  end
end
