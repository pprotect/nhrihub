FactoryBot.define do
  factory :media_appearance do
    title {Faker::Lorem.sentence(5)}

    trait :link do
      article_link { "http://www.example.com" } # so we can actually test it!
    end

    trait :file do
      file                { LoremIpsumDocument.new.docfile }
      filesize            { 10000 + (30000*rand).to_i }
      original_filename   { "#{Faker::Lorem.words(2).join("_")}.pdf" }
      original_type       { "application/pdf" }
    end

    after(:build) do |media_appearance|
      media_appearance.user_id = User.pluck(:id)
      if media_appearance.file_id
        path = Rails.env.production? ?
          Rails.root.join('..','..','shared') :
          Rails.root.join('tmp')
        original_file_path = Media::Engine.root.join('lib','sample.pdf')
        FileUtils.copy_file original_file_path, path.join('uploads','store',media_appearance.file_id) 
      end
    end

    trait :with_performance_indicators do
      after(:build) do |media_appearance|
        #media_appearance.performance_indicator_ids = PerformanceIndicator.in_current_strategic_plan.pluck(:id).last(3)
        media_appearance.performance_indicator_ids = PerformanceIndicator.in_current_strategic_plan.pluck(:id).sample(3)
      end
    end

    trait :no_f_in_title do
      title { Faker::Lorem.sentence(5).gsub(/f/i,"b") }
    end

    trait :title_has_an_f do
      title {
        str = Faker::Lorem.sentence(5)
        i = rand(str.length)
        l = str.length
        new_str = (str.dup.slice(0,i-1)+'f'+str.dup.slice(i-l,1000)).dup }
    end

    trait :hr_area do
      after(:build) do |ma|
        hr_area = Area.where(:name => "Human Rights").first
        ma.areas << hr_area
        subareas = Subarea.where(:area_id => hr_area.id).where.not(:name => "Violation")
        ma.subareas = subareas.sample(rand(6))
      end
    end

    trait :si_area do
      after(:build) do |ma|
        ma.areas << Area.where(:name => "Special Investigations Unit").first
      end
    end

    trait :gg_area do
      after(:build) do |ma|
        ma.areas << Area.where(:name => "Good Governance").first
      end
    end

    trait :crc_subarea do
      after(:build) do |ma|
        ma.subareas << Subarea.where(:name => "CRC").first
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
        hr_area = Area.where(:name => "Human Rights").first
        ma.areas << hr_area
        ma.subareas << Subarea.where(:name => "Violation", :area_id => hr_area.id).first
      end
    end
  end
end
