require 'rspec/core/shared_context'

module ProjectAdminSpecHelpers
  extend RSpec::Core::SharedContext
  before do
    Mandate::DefaultNames.each do |name|
      Mandate.create(:name => name)
    end
  end

  def delete_project_type(text)
    find(:xpath, ".//tr[contains(td,'#{text}')]").find('a').click
  end

  def model
    ProjectDocument
  end

  def filesize_selector
    '#project_document_filesize'
  end

  def filesize_context
    page.find(filesize_selector)
  end

  def filetypes_context
    page.find(filetypes_selector)
  end

  def filetypes_selector
    '#project_document_filetypes'
  end

  def admin_page
    project_admin_path('en')
  end
end
