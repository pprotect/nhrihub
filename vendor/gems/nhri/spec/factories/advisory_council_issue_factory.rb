FactoryBot.define do
  factory :advisory_council_issue, :class => Nhri::AdvisoryCouncil::AdvisoryCouncilIssue do
    title {Faker::Lorem.sentence(5)}
    user_id { User.pluck(:id).sample }

    trait :link do
      article_link { "http://www.example.com" } # so we can actually test it!
    end

    trait :file do
      file                { LoremIpsumDocument.new.upload_file }
      filesize            { 10000 + (30000*rand).to_i }
      original_filename   { "#{Faker::Lorem.words(2).join("_")}.pdf" }
      original_type       { "application/pdf" }

      after(:build) do |advisory_council_issue|
        original_file_path = Nhri::Engine.root.join('lib','sample.pdf')
        advisory_council_issue.file.attach(
          io: File.open(original_file_path),
          filename: 'sample.pdf',
          content_type: 'application/pdf',
          identify: false
        )
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

    trait :hr_subareas do
      after(:build) do |aci|
        hr_area = Nhri::AdvisoryCouncil::AdvisoryCouncilIssueArea.where(:name => "Human Rights").first
        aci.advisory_council_issue_areas << hr_area
        subareas = Nhri::AdvisoryCouncil::AdvisoryCouncilIssueSubarea.where(:area_id => hr_area.id).where.not(:name => "Violation")
        aci.advisory_council_issue_subareas << subareas.sample(sample_size = 1+rand(5))
      end
    end

    trait :si_area do
      after(:build) do |aci|
        aci.advisory_council_issue_areas << Nhri::AdvisoryCouncil::AdvisoryCouncilIssueArea.where(:name => "Special Investigations Unit").first
      end
    end

    trait :gg_area do
      after(:build) do |aci|
        gg_area = Nhri::AdvisoryCouncil::AdvisoryCouncilIssueArea.where(:name => "Good Governance").first
        aci.advisory_council_issue_areas << gg_area
        subareas = Nhri::AdvisoryCouncil::AdvisoryCouncilIssueSubarea.where(:area_id => gg_area.id)
        aci.advisory_council_issue_subareas = subareas.sample(rand(6))
      end
    end

    trait :gg_mandate do
      after(:build) do |aci|
        mandate=Mandate.find_or_create_by(:key => 'good_governance')
        aci.mandate_id = mandate.id
      end
    end

    trait :crc_subarea do
      after(:build) do |aci|
        aci.advisory_council_issue_subareas << Nhri::AdvisoryCouncil::AdvisoryCouncilIssueSubarea.where(:name => "CRC").first
      end
    end

    trait :with_notes do
      after(:create) do |aci|
        rand(3).times do
          FactoryBot.create(:note, :advisory_council_issue, :notable_id => aci.id)
        end
      end
    end

    trait :with_reminders do
      after(:create) do |aci|
        (rand(3)+1).times do
          FactoryBot.create(:reminder, :advisory_council_issue, :remindable_id => aci.id)
        end
      end
    end

    trait :hr_violation_subarea do
      after(:build) do |aci|
        hr_area = Nhri::AdvisoryCouncil::AdvisoryCouncilIssueArea.where(:name => "Human Rights").first
        aci.advisory_council_issue_areas << hr_area
        aci.advisory_council_issue_subareas << Nhri::AdvisoryCouncil::AdvisoryCouncilIssueSubarea.where(:name => "Violation", :area_id => hr_area.id).first
      end
    end
  end
end
