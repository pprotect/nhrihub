require Complaints::Engine.root.join('app', 'domain_models', 'cache')

class Complaint < ActiveRecord::Base
  include Cache
  include Rails.application.routes.url_helpers
  has_many :complaint_good_governance_complaint_bases, :dependent => :destroy
  has_many :complaint_special_investigations_unit_complaint_bases, :dependent => :destroy
  has_many :complaint_human_rights_complaint_bases, :dependent => :destroy
  has_many :good_governance_complaint_bases, :class_name => 'GoodGovernance::ComplaintBasis', :through => :complaint_good_governance_complaint_bases
  has_many :special_investigations_unit_complaint_bases, :class_name => 'Siu::ComplaintBasis', :through => :complaint_special_investigations_unit_complaint_bases
  has_many :human_rights_complaint_bases, :class_name => 'Convention', :through => :complaint_human_rights_complaint_bases
  has_many :strategic_plan_complaint_bases, :class_name => 'StrategicPlans::ComplaintBasis', :through => :complaint_strategic_plan_complaint_bases
  has_many :reminders, :as => :remindable, :autosave => true, :dependent => :destroy, :inverse_of => :remindable
  has_many :notes, :as => :notable, :autosave => true, :dependent => :destroy, :inverse_of => :notable
  has_many :assigns, :autosave => true, :dependent => :destroy
  has_many :assignees, :through => :assigns
  has_many :complaint_mandates, :dependent => :destroy
  has_many :mandates, :through => :complaint_mandates # == areas
  has_many :status_changes, :dependent => :destroy
  accepts_nested_attributes_for :status_changes
  has_many :complaint_statuses, :through => :status_changes
  has_many :complaint_agencies, :dependent => :destroy
  has_many :agencies, :through => :complaint_agencies
  has_many :complaint_documents, :dependent => :destroy
  accepts_nested_attributes_for :complaint_documents
  has_many :communications, :dependent => :destroy

  attr_accessor :witness_name

  def status_changes_attributes=(attrs)
    # only create a status_change object if this is a new complaint
    # or if the status is changing
    attrs = attrs[0]
    attrs.symbolize_keys
    change_date = attrs[:change_date].nil? ? DateTime.now : DateTime.new(attrs[:change_date])
    user_id = attrs[:user_id]
    if !persisted?
      complaint_status = ComplaintStatus.find_or_create_by(:name => "Under Evaluation")
      complaint_status_id = complaint_status.id
      status_changes.build({:user_id => user_id,
                            :change_date => change_date,
                            :complaint_status_id => complaint_status_id})
    elsif !(attrs[:name].nil? || attrs[:name] == "null") && attrs[:name] != current_status_humanized
      complaint_status = ComplaintStatus.find_or_create_by(:name => attrs[:name])
      complaint_status_id = complaint_status.id
      status_changes.build({:user_id => user_id,
                            :change_date => change_date,
                            :complaint_status_id => complaint_status_id})
    end
  end

  before_save do |complaint|
    # workaround hack b/c FormData object sends "null" string for null values
    string_or_text_columns = Complaint.columns.select{|c| (c.type == :string) || (c.type == :text)}.map(&:name)
    string_or_text_columns.each do |column_name|
      complaint.send("#{column_name}=", nil) if complaint.send(column_name) == "null" || complaint.send(column_name) == "undefined"
    end
    integer_columns = Complaint.columns.select{|c| c.type == :integer}.map(&:name)
    # it's a hack... TODO there must be a better way!
    integer_columns.each do |column_name|
      complaint.send("#{column_name}=",nil) if complaint.send(column_name).nil? || complaint.send(column_name).zero?
    end
  end

  before_create do |complaint|
    if complaint.date_received.nil? || complaint.date_received == "undefined" || complaint.date_received == "null"
      complaint.date_received = DateTime.now
    end
  end

  def <=>(other)
    CaseReference.new(case_reference) <=> CaseReference.new(other.case_reference)
  end

  def as_json(options = {})
    super( :methods => [:reminders,
                        :notes,
                        :assigns,
                        :current_assignee_id,
                        :current_assignee_name,
                        :date,
                        :date_of_birth,
                        :dob,
                        :current_status_humanized,
                        :attached_documents,
                        :mandate_ids,
                        :good_governance_complaint_basis_ids,
                        :special_investigations_unit_complaint_basis_ids,
                        :human_rights_complaint_basis_ids,
                        :agency_ids,
                        :status_changes,
                        :communications])
  end

  # overwrite the built-in method, as this approach does not add extra sql queries
  def mandate_ids
    mandates.map(&:id)
  end

  def good_governance_complaint_basis_ids
    complaint_good_governance_complaint_bases.map(&:complaint_basis_id)
  end

  def special_investigations_unit_complaint_basis_ids
    complaint_special_investigations_unit_complaint_bases.map(&:complaint_basis_id)
  end

  def human_rights_complaint_basis_ids
    complaint_human_rights_complaint_bases.map(&:complaint_basis_id)
  end

  def agency_ids
    complaint_agencies.map(&:agency_id)
  end

  # assumed to be valid date_string, checked in client before submitting
  def dob=(date_string)
    write_attribute("dob", Date.parse(date_string))
  end

  def dob
    read_attribute("dob").strftime("%d/%m/%Y") unless read_attribute("dob").blank?
  end

  def date_of_birth
    read_attribute("dob").strftime("%b %e, %Y") unless read_attribute("dob").blank?
  end

  def attached_documents
    complaint_documents
  end

  def self.next_case_reference
    case_references = CaseReferenceCollection.new(all.pluck(:case_reference))
    case_references.next_ref
  end

  def closed?
    !current_status
  end

  def current_status
    status_changes.last.complaint_status.name
  end

  def current_status_humanized
    status_changes.last.status_humanized unless status_changes.empty?
  end

  def _complained_to_subject_agency
    complained_to_subject_agency ? 'yes' : 'no'
  end

  def agency_names
    list = agencies.map(&:description)
    def list.to_s
      self.map{|item| "<w:p><w:t>#{ERB::Util.html_escape(item)}</w:t></w:p>"}.join()
    end
    list
  end

  def date
    date_received.strftime("%b %-e, %Y") unless date_received.nil?
  end

  def date=(val)
    unless val=="undefined" || val=="null" || val.nil? || val.blank?
      write_attribute(:date_received, Date.parse(val))
    end
  end

  def report_date
    date_received.to_date.to_s
  end

  def current_assignee_name
    current_assignee.first_last_name if current_assignee
  end

  def current_assignee
    # default order for assigns is most-recent-first
    @current_assignee ||= assigns.first.assignee unless assigns.empty?
  end

  def new_assignee_id=(id)
    unless id.blank? || id=="null" || id=="undefined" || id=='0'
      self.assignees << User.find(id)
    end
  end

  def current_assignee_id
    current_assignee.id if current_assignee
  end

  def notable_url(notable_id)
    complaint_note_path('en',id,notable_id)
  end

  def remindable_url(remindable_id)
    complaint_reminder_path('en',id,remindable_id)
  end

  def index_url
    complaints_url('en', {:host => SITE_URL, :protocol => 'https', :case_reference => case_reference})
  end

  def complainant_full_name
    [chiefly_title, firstName, lastName].join(' ')
  end

  def gender_full_text
    case gender
    when "M"
      "male"
    when "F"
      "female"
    when "O"
      "other"
    else
      ""
    end
  end
end
