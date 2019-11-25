FactoryBot.define do
  factory :media_appearance do
    title {Faker::Lorem.sentence(word_count: 5)}
    user_id { User.pluck(:id).sample }

    trait :link do
      article_link { "http://www.example.com" } # so we can actually test it!
    end

    trait :file do
      file                { LoremIpsumDocument.new.upload_file }
      filesize            { 10000 + (30000*rand).to_i }
      original_filename   { "#{Faker::Lorem.words(number: 2).join("_")}.pdf" }
      original_type       { "application/pdf" }

      after(:build) do |media_appearance|
        original_file_path = Media::Engine.root.join('lib','sample.pdf')
        media_appearance.file.attach(
          io: File.open(original_file_path),
          filename: 'sample.pdf',
          content_type: 'application/pdf',
          identify: false
        )
      end
    end


    trait :with_performance_indicators do
      after(:build) do |media_appearance|
        media_appearance.performance_indicator_ids = PerformanceIndicator.in_current_strategic_plan.pluck(:id).sample(3)
      end
    end

    trait :no_f_in_title do
      title { Faker::Lorem.sentence(word_count: 5).gsub(/f/i,"b") }
    end

    trait :title_has_an_f do
      title {
        str = Faker::Lorem.sentence(word_count: 5)
        i = rand(str.length)
        l = str.length
        new_str = (str.dup.slice(0,i-1)+'f'+str.dup.slice(i-l,1000)).dup }
    end

    trait :hr_subareas do
      after(:build) do |ma|
        hr_area = MediaArea.find_or_create_by(:name => "Human Rights")
        ma.media_areas << hr_area
        subareas = Subarea::DefaultNames[:"Human Rights"][0..1].collect do |subarea_name|
          MediaSubarea.find_or_create_by(:area_id => hr_area.id, :name => subarea_name)
        end
        ma.media_subareas << subareas
      end
    end

    trait :si_area do
      after(:build) do |ma|
        si_area = MediaArea.find_or_create_by(:name => "Special Investigations Unit")
        ma.media_areas << si_area
        subareas = Subarea::DefaultNames[:"Special Investigations Unit"].sample(2).collect do |subarea_name|
          MediaSubarea.find_or_create_by(:area_id => si_area.id, :name => subarea_name)
        end
        ma.media_subareas << subareas
      end
    end

    trait :gg_area do
      after(:build) do |ma|
        gg_area = MediaArea.find_or_create_by(:name => "Good Governance")
        ma.media_areas << gg_area
        subareas = Subarea::DefaultNames[:"Good Governance"].sample(2).collect do |subarea_name|
          MediaSubarea.find_or_create_by(:area_id => gg_area.id, :name => subarea_name)
        end
        ma.media_subareas << subareas
      end
    end

    trait :gg_mandate do
      after(:build) do |ma|
        gg_mandate = Mandate.find_or_create_by(:name => 'Good Governance')
        ma.mandate_id = gg_mandate.id
      end
    end

    trait :crc_subarea do
      after(:build) do |ma|
        ma.media_subareas << MediaSubarea.find_or_create_by(:name => "CRC")
      end
    end

    trait :with_notes do
      after(:create) do |ma|
        rand(3).times do
          FactoryBot.create(:note, :media_appearance, :notable_id => ma.id)
        end
      end
    end

    trait :with_reminders do
      after(:create) do |ma|
        rand(3).times do
          FactoryBot.create(:reminder, :media_appearance, :remindable_id => ma.id)
        end
      end
    end

    trait :hr_violation_subarea do
      after(:build) do |ma|
        hr_area = MediaArea.find_or_create_by(:name => "Human Rights")
        ma.media_areas << hr_area
        ma.media_subareas << MediaSubarea.find_or_create_by(:name => "Violation", :area_id => hr_area.id)
      end
    end
  end
end
