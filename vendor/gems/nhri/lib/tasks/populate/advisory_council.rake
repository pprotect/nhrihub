namespace :nhri do
  namespace :advisory_council do
    namespace :terms_of_reference do
      task :depopulate=> :environment do
        Nhri::AdvisoryCouncil::TermsOfReferenceVersion.destroy_all
      end

      desc "populates terms of reference"
      task :populate => "nhri:advisory_council:terms_of_reference:depopulate" do
        3.times do |i|
          FactoryBot.create(:terms_of_reference_version, :revision_major => i+1, :revision_minor => 0)
        end
      end
    end

    namespace :membership do
      task :depopulate => :environment do
        AdvisoryCouncilMember.destroy_all
      end

      desc "populates advisory council members list"
      task :populate => "nhri:advisory_council:membership:depopulate" do
        3.times do
          FactoryBot.create(:advisory_council_member)
        end
      end
    end

    namespace :meeting_minutes do
      task :depopulate => :environment do
        Nhri::AdvisoryCouncil::AdvisoryCouncilMinutes.destroy_all
      end

      desc "populates advisory council minutes list"
      task :populate => "nhri:advisory_council:meeting_minutes:depopulate" do
        3.times do
          FactoryBot.create(:advisory_council_minutes)
        end
      end
    end

    desc "populates complaint areas and subareas"
    task :populate_areas_subareas => :environment do
      Nhri::AdvisoryCouncil::AdvisoryCouncilIssueArea.destroy_all
      Nhri::AdvisoryCouncil::AdvisoryCouncilIssueSubarea.destroy_all
      Subarea::DefaultNames.each do |name,subareas|
        area = FactoryBot.create(:issue_area, name: name)

        subareas.each do |subarea_name|
          FactoryBot.create(:issue_subarea, area_id: area.id, name: subarea_name)
        end
      end
    end

    namespace :issues do
      task :depopulate => :environment do
        Nhri::AdvisoryCouncil::AdvisoryCouncilIssue.destroy_all
      end

      desc "populates advisory council issues"
      task :populate => ["nhri:advisory_council:issues:depopulate","nhri:advisory_council:populate_areas_subareas"] do
        20.times do
          ma = FactoryBot.create(:advisory_council_issue,
                                 :with_reminders,
                                 :with_notes,
                                 [:hr_area, :si_area, :gg_area, :hr_violation_subarea].sample,
                                 :created_at => Date.today.advance(:days => -(rand(365))).to_datetime)
        end
      end
    end
  end
end
