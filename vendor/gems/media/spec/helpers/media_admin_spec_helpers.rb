require 'rspec/core/shared_context'

module MediaAdminSpecHelpers
  extend RSpec::Core::SharedContext

  before do
    create_default_areas
    visit media_appearance_admin_path('en')
  end

  def setup_default_audience_types
    AudienceType::DefaultValues.each do |at|
      AudienceType.create(:short_type => at.short_type, :long_type => at.long_type)
    end
  end

  def audience_types_long_descriptions
    page.all('#audience_types .audience_type .long_type').map(&:text)
  end

  def audience_types_short_descriptions
    page.all('#audience_types .audience_type .short_type').map(&:text)
  end

  def add_audience_type
    page.find('button#add_audience_type')
  end

  def delete_first_audience_type
    page.all('.delete_audience_type').first.click
  end

  def remove_add_delete_fileconfig_permissions
    allow_any_instance_of(AuthorizedSystem).to receive(:permitted?).with('media_appearance/filetypes','create').and_return(false)
    allow_any_instance_of(AuthorizedSystem).to receive(:permitted?).with('media_appearance/filetypes','destroy').and_return(false)
    allow_any_instance_of(AuthorizedSystem).to receive(:permitted?).with('media_appearance/filetypes','update').and_return(false)
    allow_any_instance_of(AuthorizedSystem).to receive(:permitted?).with('media_appearance/filesizes','create').and_return(false)
    allow_any_instance_of(AuthorizedSystem).to receive(:permitted?).with('media_appearance/filesizes','destroy').and_return(false)
    allow_any_instance_of(AuthorizedSystem).to receive(:permitted?).with('media_appearance/filesizes','update').and_return(false)
  end

  def create_default_areas
    ["Human Rights", "Good Governance", "Special Investigations Unit", "Corporate Services"].each do |a|
      MediaIssueArea.create(:name => a)
    end
    human_rights_id = MediaIssueArea.where(:name => 'Human Rights').first.id
    [{:area_id => human_rights_id, :name => "Violation", :full_name => "Violation"},
    {:area_id => human_rights_id, :name => "Education activities", :full_name => "Education activities"},
    {:area_id => human_rights_id, :name => "Office reports", :full_name => "Office reports"},
    {:area_id => human_rights_id, :name => "Universal periodic review", :full_name => "Universal periodic review"},
    {:area_id => human_rights_id, :name => "CEDAW", :full_name => "Convention on the Elimination of All Forms of Discrimination against Women"},
    {:area_id => human_rights_id, :name => "CRC", :full_name => "Convention on the Rights of the Child"},
    {:area_id => human_rights_id, :name => "CRPD", :full_name => "Convention on the Rights of Persons with Disabilities"}].each do |attrs|
      MediaIssueSubarea.create(attrs)
    end

    good_governance_id = MediaIssueArea.where(:name => "Good Governance").first.id

    [{:area_id => good_governance_id, :name => "Violation", :full_name => "Violation"},
    {:area_id => good_governance_id, :name => "Office report", :full_name => "Office report"},
    {:area_id => good_governance_id, :name => "Office consultations", :full_name => "Office consultations"}].each do |attrs|
      MediaIssueSubarea.create(attrs)
    end
  end

  def model
    MediaAppearance
  end

  def filesize_selector
    '#media_appearance_filesize'
  end

  def filesize_context
    page.find(filesize_selector)
  end

  def filetypes_context
    page.find(filetypes_selector)
  end

  def filetypes_selector
    '#media_appearance_filetypes'
  end

  def admin_page
    media_appearance_admin_path('en')
  end
end
