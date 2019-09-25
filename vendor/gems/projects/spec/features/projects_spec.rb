require 'rails_helper'
$:.unshift File.expand_path '../../helpers', __FILE__
require 'login_helpers'
require 'navigation_helpers'
require 'download_helpers'
require 'projects_spec_helpers'
require 'upload_file_helpers'
require 'projects_context_performance_indicator_spec_helpers'
require 'performance_indicator_helpers'
require 'performance_indicator_association'

feature "projects index", :js => true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include IERemoteDetector
  include NavigationHelpers
  include ProjectsSpecHelpers
  include UploadFileHelpers
  include DownloadHelpers

  feature "list behaviour" do
    it "should show a list of projects" do
      expect(page_heading).to eq "Projects"
      expect(page_title).to eq "Projects"
      expect(Project.count).to eq 2
      expect(projects_count).to eq 2
    end

    it "pre-populates the projects filter when a title is passed in the url" do
      url = URI(@project.index_url)
      visit @project.index_url.gsub(%r{.*#{url.host}},'') # hack, don't know how else to do it, host otherwise is SITE_URL defined in lib/constants
      expect(number_of_rendered_projects).to eq 1
      expect(number_of_all_projects).to eq 2
      expect(page.find('#projects_controls #title').value).to eq @project.title
      clear_filter_fields
      expect(number_of_rendered_projects).to eq 2
      expect(query_string).to be_blank
      click_back_button
      expect(page.evaluate_script("window.location.search")).to eq "?title=#{(ERB::Util.url_encode(@project.title)).gsub(/%20/,'+')}"
      expect(number_of_rendered_projects).to eq 1
    end

    it "shows expanded information for each of the projects" do
      expand_last_project
      within last_project do
        last_project = Project.find(2)
        expect(find('.basic_info .title').text).to eq last_project.title
        expect(find('.description .col-md-10 .no_edit span').text).to eq last_project.description
        expect(find('#mandate #name').text).to eq last_project.mandate.name
        within subareas do
          expect(good_governance_subareas).to match_array last_project.project_subareas.good_governance.map(&:name)
          expect(human_rights_subareas).to match_array last_project.project_subareas.human_rights.map(&:name)
        end
        within performance_indicators do
          expect(performance_indicator_descriptions).to match_array last_project.performance_indicators.map(&:indexed_description)
        end
        within project_documents do
          last_project.project_documents.each do |project_document|
            expect(all('.project_document .title').map(&:text)).to include project_document.title
          end
        end
      end
    end
  end

  feature "adding or deleting a project" do
    it "adds a project that does not have a file attachment" do
      add_project.click
      fill_in('project_title', :with => "new project title")
      fill_in('project_description', :with => "new project description")
      choose('Good Governance')

      check_subarea("Good Governance", "Consultation")

      add_a_performance_indicator

      # SAVE IT
      #page.execute_script("scrollTo(0,0)")
      expect{ save_project.click; wait_for_ajax }.to change{ Project.count }.from(2).to(3)

      # CHECK SERVER
      pi = PerformanceIndicator.first
      project = Project.last
      expect(project.performance_indicator_ids).to eq [pi.id]
      expect(projects_count).to eq 3
      expect(project.title).to eq "new project title"
      expect(project.description).to eq "new project description"
      mandate = Mandate.find_by(:key => "good_governance")
      expect(project.mandate_id).to eq mandate.id

      # CHECK CLIENT
      expand_first_project
      within first_project do
        expect(find('.project .basic_info .title').text).to eq "new project title"
        expect(find('.description .col-md-10 .no_edit span').text).to eq "new project description"
        expect(find('#mandate #name').text).to eq 'Good Governance'
        within subareas do
          expect(good_governance_subareas).to eq ['Consultation']
        end
        within performance_indicators do
          expect(performance_indicator_descriptions).to eq [pi.indexed_description]
        end
      end
    end

    it "adds a project that has a file attachment" do
      add_project.click
      fill_in('project_title', :with => "new project title")
      fill_in('project_description', :with => "new project description")
      choose('Good Governance')

      check_subarea("Good Governance", "Consultation")

      add_a_performance_indicator

      within new_project do
        attach_file("project_fileinput", upload_document)
        fill_in("project_document_title", :with => "Project Document")
      end
      expect(page).to have_selector("#documents .document .filename", :text => "upload_file.pdf")

      within new_project do
        attach_file("project_fileinput", upload_document)
        page.all("#project_document_title")[0].set("Title for an analysis document")
      end
      expect(page).to have_selector("#documents .document .filename", :text => "upload_file.pdf", :count => 2)

      # SAVE IT
      page.execute_script("scrollTo(0,0)")
      expect{ save_project.click; wait_for_ajax }.to change{ Project.count }.from(2).to(3).
                                               and change{ ProjectDocument.count }.by(2)

      # CHECK SERVER
      pi = PerformanceIndicator.first
      project = Project.last
      expect(project.performance_indicator_ids).to eq [pi.id]
      expect(projects_count).to eq 3
      expect(project.title).to eq "new project title"
      expect(project.description).to eq "new project description"
      mandate = Mandate.find_by(:key => "good_governance")
      expect(project.mandate_id).to eq mandate.id

      expect(project.project_documents.count).to eq 2
      expect(project.project_documents.map(&:title)).to include "Project Document"
      expect(project.project_documents.map(&:title)).to include "Title for an analysis document"

      # CHECK CLIENT
      expand_first_project
      within first_project do
        expect(find('.basic_info .title').text).to eq "new project title"
        expect(find('.description .col-md-10 .no_edit span').text).to eq "new project description"
        expect(find('#mandate #name').text).to eq 'Good Governance'
        within subareas do
          expect(good_governance_subareas).to eq ['Consultation']
        end
        within performance_indicators do
          expect(find('.performance_indicator').text).to eq pi.indexed_description
        end
        within project_documents do
          expect(all('.project_document .title').map(&:text)).to include "Project Document"
          expect(all('.project_document .title').map(&:text)).to include "Title for an analysis document"
        end
      end
    end

    it "flags as invalid when file attachment exceeds permitted filesize" do
      add_project.click

      within new_project do
        attach_file("project_fileinput", big_upload_document)
      end
      expect(page).to have_selector('#filesize_error', :text => "File is too large")

      expect{ save_project.click; wait_for_ajax }.not_to change{ Project.count }
    end

    it "flags as invalid when file attachment is unpermitted filetype" do
      add_project.click

      within new_project do
        attach_file("project_fileinput", upload_image)
      end
      expect(page).to have_css('#filetype_error', :text => "File type not allowed")

      expect{ save_project.click; wait_for_ajax }.not_to change{ Project.count }
    end

    it "should restore list when cancelling add project" do
      add_project.click
      fill_in('project_title', :with => "new project title")
      fill_in('project_description', :with => "new project description")
      cancel_project.click
      expect(projects_count).to eq 2
      add_project.click
      expect(page.find('#project_title').value).to eq ""
      expect(page.find('#project_description').value).to eq ""
    end


    it "should show warning and not add when title is blank" do
      add_project.click
      fill_in('project_description', :with => "new project description")
      add_a_performance_indicator
      expect{ save_project.click; wait_for_ajax }.not_to change{ Project.count }
      expect(page).to have_selector("#title_error", :text => "Title cannot be blank")
      expect(page).to have_selector("#project_error", :text => "Form has errors, cannot be saved")
      fill_in('project_title', :with => 't')
      expect(page).not_to have_selector("#title_error", :text => "Title cannot be blank")
      expect(page).not_to have_selector("#project_error", :text => "Form has errors, cannot be saved")
    end

    it "should show warning and not add when title is whitespace" do
      add_project.click
      fill_in('project_title', :with => "    ")
      fill_in('project_description', :with => "new project description")
      add_a_performance_indicator
      expect{ save_project.click; wait_for_ajax }.not_to change{ Project.count }
      expect(page).to have_selector("#title_error", :text => "Title cannot be blank")
      expect(page).to have_selector("#project_error", :text => "Form has errors, cannot be saved")
      fill_in('project_title', :with => 't')
      expect(page).not_to have_selector("#title_error", :text => "Title cannot be blank")
      expect(page).not_to have_selector("#project_error", :text => "Form has errors, cannot be saved")
    end

    it "should show warning and not add when description is blank" do
      add_project.click
      fill_in('project_title', :with => "new project title")
      add_a_performance_indicator
      expect{ save_project.click; wait_for_ajax }.not_to change{ Project.count }
      expect(page).to have_selector("#description_error", :text => "Description cannot be blank")
      expect(page).to have_selector("#project_error", :text => "Form has errors, cannot be saved")
      fill_in('project_description', :with => 't')
      expect(page).not_to have_selector("#description_error", :text => "Description cannot be blank")
      expect(page).not_to have_selector("#project_error", :text => "Form has errors, cannot be saved")
    end

    it "should show warning and not add when description is whitespace" do
      add_project.click
      fill_in('project_title', :with => "new project title")
      fill_in('project_description', :with => "   ")
      add_a_performance_indicator
      expect{ save_project.click; wait_for_ajax }.not_to change{ Project.count }
      expect(page).to have_selector("#description_error", :text => "Description cannot be blank")
      expect(page).to have_selector("#project_error", :text => "Form has errors, cannot be saved")
      fill_in('project_description', :with => 't')
      expect(page).not_to have_selector("#description_error", :text => "Description cannot be blank")
      expect(page).not_to have_selector("#project_error", :text => "Form has errors, cannot be saved")
    end

    it "should show warning and not add when performance_indicator is not linked" do
      add_project.click
      fill_in('project_title', :with => "new project title")
      fill_in('project_description', :with => "described by words")
      expect{ save_project.click; wait_for_ajax }.not_to change{ Project.count }
      expect(page).to have_selector("#performance_indicator_associations_error", :text => "There must be at least one performance indicator")
      expect(page).to have_selector("#project_error", :text => "Form has errors, cannot be saved")
      add_a_performance_indicator
      expect(page).not_to have_selector("#performance_indicator_associations_error", :text => "There must be at least one performance indicator")
      expect(page).not_to have_selector("#project_error", :text => "Form has errors, cannot be saved")
    end

    it "should prevent adding more than one project at a time" do
      add_project.click
      add_project.click
      expect(page.all('.new_project').count).to eq 1
      cancel_project.click
      expect(page.all('.new_project').count).to eq 0
      add_project.click
      expect(page.all('.new_project').count).to eq 1
    end

    it "should delete a project" do
      expect{ delete_project_icon.click; confirm_deletion; wait_for_ajax }.to change{ Project.count }.by(-1).
                                                                           and change{ projects_count }.by(-1)
    end
  end

  feature "editing a project" do
    it "should edit a project with a file" do
      edit_first_project.click
      fill_in('project_title', :with => "new project title")
      fill_in('project_description', :with => "new project description")
      choose('Good Governance')

      check_subarea("Good Governance", "Consultation")
      check_subarea("Human Rights", "Amicus Curiae")

      pi = add_a_performance_indicator

      attach_file("project_fileinput", upload_document)
      fill_in("project_document_title", :with => "Adding another doc")
      expect(page).to have_selector("#project_documents .document .filename", :text => "upload_file.pdf")

      attach_file("project_fileinput", upload_document)
      page.all("#project_document_title")[0].set("Adding still another doc")
      expect(page).to have_selector("#project_documents .document .filename", :text => "upload_file.pdf", :count => 2)

      expect{ edit_save}.to change{ Project.find(1).title }.to("new project title")
      project = Project.find(1)
      consultation_project_type = ProjectSubarea.find_by(:name => "Consultation")
      expect( project.subarea_ids ).to include consultation_project_type.id
      amicus_project_type = ProjectSubarea.find_by(:name => "Amicus Curiae")
      expect( project.subarea_ids ).to include amicus_project_type.id
      expect( project.project_documents.count ).to eq 4

      expand_first_project

      within first_project do
        expect(find('.basic_info .title').text).to eq "new project title"
        expect(find('.description .col-md-10 .no_edit span').text).to eq "new project description"
        expect(find('#mandate #name').text).to eq 'Good Governance'
        within subareas do
          expect(good_governance_subareas).to eq ['Consultation']
        end
        within performance_indicators do
          expect(all('.performance_indicator').map(&:text)).to include pi.indexed_description
        end
        within project_documents do
          expect(all('.project_document .title').map(&:text)).to include "Adding still another doc"
          expect(all('.project_document .title').map(&:text)).to include "Adding another doc"
        end
      end
    end

    # test this b/c of special handling of checkboxes in ractive
    it "should edit a project and save when all checkboxes are unchecked" do
      edit_last_project.click # has all associations checked
      uncheck_all_checkboxes
      expect{ edit_save }.to change{Project.last.subarea_ids}.to([])
    end

    it "should restore prior values if editing is cancelled" do
      edit_first_project.click
      fill_in('project_title', :with => "new project title")
      fill_in('project_description', :with => "new project description")
      choose('Good Governance')

      check_subarea("Human Rights", "Amicus Curiae")

      add_a_performance_indicator

      edit_cancel

      expand_first_project

      project = Project.first
      within first_project do
        expect(find('.basic_info .title').text).to eq project.title
        expect(find('.description .col-md-10 .no_edit span').text).to eq project.description
        expect(find('#mandate #name').text).to be_blank
        expect(all('.subarea').count).to eq 0
        expect(all('.performance_indicator').count).to eq project.performance_indicator_ids.count
      end

      edit_first_project.click

      expect(page.find('#project_title').value).to eq project.title
      expect(page.find('#project_description').value).to eq project.description
      ['good_governance', 'human_rights', 'corporate_services', 'special_investigations_unit'].each do |id|
        expect(radio(id)).not_to be_checked
      end
      expect(checkbox('subarea_1')).not_to be_checked
      expect(checkbox('subarea_2')).not_to be_checked
      expect(checkbox('subarea_3')).not_to be_checked
      expect(checkbox('subarea_4')).not_to be_checked
      expect(checkbox('subarea_5')).not_to be_checked
    end

    it "should show warning and not save when editing and title is blank" do
      edit_first_project.click
      fill_in('project_title', :with => '')
      expect{ edit_save }.not_to change{ Project.find(1).title }
      expect(page).to have_selector("#title_error", :text => "Title cannot be blank")
      expect(page).to have_selector("#project_error", :text => "Form has errors, cannot be saved")
      fill_in('project_title', :with => 't')
      expect(page).not_to have_selector("#title_error", :text => "Title cannot be blank")
      expect(page).not_to have_selector("#project_error", :text => "Form has errors, cannot be saved")
    end

    it "should show warning and not save edited project when title is whitespace" do
      edit_first_project.click
      fill_in('project_title', :with => "   ")
      expect{ edit_save}.not_to change{ Project.find(1).title }
      expect(page).to have_selector("#title_error", :text => "Title cannot be blank")
      expect(page).to have_selector("#project_error", :text => "Form has errors, cannot be saved")
      fill_in('project_title', :with => 't')
      expect(page).not_to have_selector("#title_error", :text => "Title cannot be blank")
      expect(page).not_to have_selector("#project_error", :text => "Form has errors, cannot be saved")
    end

    it "should show warning and not save edited project when description is blank" do
      edit_first_project.click
      fill_in('project_description', :with => "")
      expect{ edit_save}.not_to change{ Project.find(1).description }
      expect(page).to have_selector("#description_error", :text => "Description cannot be blank")
      expect(page).to have_selector("#project_error", :text => "Form has errors, cannot be saved")
      fill_in('project_description', :with => 't')
      expect(page).not_to have_selector("#description_error", :text => "Description cannot be blank")
      expect(page).not_to have_selector("#project_error", :text => "Form has errors, cannot be saved")
    end

    it "should show warning and not save edited project when description is whitespace" do
      edit_first_project.click
      fill_in('project_description', :with => "  ")
      expect{ edit_save}.not_to change{ Project.find(1).description }
      expect(page).to have_selector("#description_error", :text => "Description cannot be blank")
      expect(page).to have_selector("#project_error", :text => "Form has errors, cannot be saved")
      fill_in('project_description', :with => 't')
      expect(page).not_to have_selector("#description_error", :text => "Description cannot be blank")
      expect(page).not_to have_selector("#project_error", :text => "Form has errors, cannot be saved")
    end

    it "should terminate adding if editing is initiated" do
      add_project.click
      expect(page).to have_selector('.new_project')
      edit_first_project.click
      expect(page).not_to have_selector('.new_project')
    end

    it "should terminate editing if adding is initiated" do
      edit_first_project.click
      expect(page).to have_selector('#projects .project textarea#project_description', :visible => true)
      add_project.click
      expect(page).not_to have_selector('#projects .project textarea#project_description', :visible => true)
    end

    it "should prevent editing more than one project at at time" do
      edit_first_project.click
      edit_last_project.click
      expect(page).to have_selector('#projects .project textarea#project_description', :visible => true, :count => 1)
    end
  end

  it "should download a project document file" do
    expand_first_project
    @doc = ProjectDocument.first
    filename = @doc.original_filename
    click_the_download_icon
    unless page.driver.instance_of?(Capybara::Selenium::Driver) # response_headers not supported
      expect(page.response_headers['Content-Type']).to eq('application/pdf')
      expect(page.response_headers['Content-Disposition']).to eq("attachment; filename=\"#{filename}\"")
    end
    expect(downloaded_file).to eq filename
  end
end

feature "performance indicator association", :js => true do
  include ProjectsContextPerformanceIndicatorSpecHelpers
  it_behaves_like "has performance indicator association"
end

feature "filter controls dropdown options", :js => true do # b/c there was a bug
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include ProjectsSpecHelpers

  # all_areas (areas) Mandate.all, all_area_project_types (project_types) ProjectTypes.mandate_groups, planned_results (planned_results) PlannedResult.all_with_associations
  it "populates area, subarea, and performance_indicator dropdowns" do
    page.find('button', :text => 'Select area').click
    Mandate.all.each do |area|
      expect(page).to have_selector('#area_filter_select li a span', :text => area.name)
    end
    page.find('button', :text => 'Select project type').click
    ProjectSubarea.pluck(:name).each do |name|
      expect(page).to have_selector('#subarea_filter_select li a span', :text => name)
    end
    page.find('button', :text => 'Select performance indicators').click
    PerformanceIndicator.in_current_strategic_plan.all.each do |pi|
      expect(page).to have_selector('#performance_indicator_filter_select .planned_result .outcome .activity li.performance_indicator a span.text', :text => pi.indexed_description)
    end
  end
end

feature "default area subarea filters", :js => true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include ProjectsSpecHelpers

  before do
    project_without_areas = FactoryBot.create(:project, :with_subareas, :title => 'no areas')
    project_without_subareas = FactoryBot.create(:project, :with_mandate, :title => 'no subareas')
    project_without_areas_or_subareas = FactoryBot.create(:project, :title => 'no areas or subareas')
    project_with_areas_and_subareas = FactoryBot.create(:project, :with_mandate, :with_subareas, :title => 'has areas and subareas')
  end

  it "should show all projects, including those with no area or subarea designation by default" do
    visit projects_path(:en)
    expect(number_of_rendered_projects).to eq 6
  end

end
