def first_names
  number = [1,2,3].sample
  names = []
  number.times do
    names << Faker::Name.first_name
  end
  names.join(' ')
end

def id_attribute
  type = [1,2].sample
  value = case type
          when 1
            Faker::Alphanumeric.alphanumeric(number: 9)
          when 2
            Faker::SouthAfrica.id_number
          end
  {type: type, value: value}
end

def sa_city
  Faker::Config.locale = "en-ZA"
  city = Faker::Address.city
  Faker::Config.locale = "en"
  city
end

def sa_province
  Faker::Config.locale = "en-ZA"
  province = Faker::Address.provinces
  Faker::Config.locale = "en"
  Province.find_or_create_by(name: province)
end

def sa_postal_code
  Faker::Config.locale = "en-ZA"
  post_code = Faker::Address.zip_code
  Faker::Config.locale = "en"
  post_code
end

FactoryBot.define do
  factory :complainant do
    firstName { first_names }
    lastName { Faker::Name.last_name }
    occupation { Faker::Company.profession }
    employer { Faker::Company.name }
    email { Faker::Internet.email }
    gender { ["m","f","o"].sample }
    dob { y=20+rand(40); m=rand(12); d=rand(31); Date.today.advance(:years => -y, :months => -m, :days => -d).to_s }
    title { Faker::Name.prefix }
    id_type { id_attribute[:type] }
    id_value { id_attribute[:value] }
    alt_id_type { Complainant.alt_id_types.except("undefined").keys.sample }
    alt_id_value { rand(10000000)+1000000 }
    physical_address { Faker::Address.street_address }
    postal_address { "PO Box #{rand(5000)}" }
    city { sa_city }
    province_id { sa_province.id }
    postal_code { sa_postal_code }
    cell_phone { Faker::SouthAfrica.cell_phone }
    home_phone { Faker::SouthAfrica.phone_number }
    fax { Faker::SouthAfrica.phone_number }
    preferred_means { [0,1,2,3].sample }
  end
end

