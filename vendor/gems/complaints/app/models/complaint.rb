require Complaints::Engine.root.join('app', 'domain_models', 'cache')

class Complaint < ActiveRecord::Base
  include Cache
  include Rails.application.routes.url_helpers
  has_many :complaint_complaint_areas, :dependent => :destroy
  has_many :complaint_areas, :through => :complaint_complaint_areas
  has_many :complaint_complaint_subareas, :dependent => :destroy
  has_many :complaint_subareas, :through => :complaint_complaint_subareas
  has_many :reminders, :as => :remindable, :autosave => true, :dependent => :destroy, :inverse_of => :remindable
  has_many :notes, :as => :notable, :autosave => true, :dependent => :destroy, :inverse_of => :notable
  has_many :assigns, :autosave => true, :dependent => :destroy
  has_many :assignees, :through => :assigns
  belongs_to :mandate # == areas
  has_many :status_changes, :dependent => :destroy
  accepts_nested_attributes_for :status_changes
  has_many :complaint_statuses, :through => :status_changes
  has_many :complaint_agencies, :dependent => :destroy
  has_many :agencies, :through => :complaint_agencies
  has_many :complaint_documents, :dependent => :destroy
  accepts_nested_attributes_for :complaint_documents
  has_many :communications, :dependent => :destroy

  attr_accessor :witness_name

  def self.filtered(query)
    for_assignee(query[:selected_assignee_id]).
      with_status(query[:selected_status_ids]).
      with_mandates(query[:selected_mandate_ids]).
      with_case_reference_match(query[:case_reference]).
      with_complainant_match(query[:complainant]).
      since_date(query[:from]).
      before_date(query[:to]).
      with_village(query[:village]).
      with_phone(query[:phone]).
      with_subareas(query[:selected_subarea_ids]).
      with_agencies(query[:selected_agency_ids])
  end

  def self.with_agencies(selected_agency_ids)
    selected_agency_ids = nil if selected_agency_ids.delete_if(&:blank?).empty?
    joins(:complaint_agencies).where("complaint_agencies.agency_id in (?)", selected_agency_ids)
  end

  def self.with_subareas(selected_subarea_ids)
    selected_subarea_ids = nil if selected_subarea_ids.delete_if(&:blank?).empty?

    joins(:complaint_complaint_subareas).
      where( "complaint_complaint_subareas.subarea_id in (?)", selected_subarea_ids)
  end

  def self.with_mandates(selected_mandate_ids)
    where(mandate_id: selected_mandate_ids)
  end

  def self.with_phone(phone_fragment)
    digits = phone_fragment&.delete('^0-9')
    if digits.nil? || digits.empty?
      where("1=1")
    else
      where("complaints.phone ~ '.*#{digits}.*'")
    end
  end

  def self.with_village(village_fragment)
    if village_fragment.blank?
      where("1=1")
    else
      where("\"complaints\".\"village\" ~* '.*#{village_fragment}.*'")
    end
  end

  def self.since_date(from)
    if from.blank?
      where('1=1')
    else
      where("complaints.date_received >= ?", Time.parse(from).beginning_of_day) # need to convert the argument to UTC
    end
  end

  def self.before_date(to)
    if to.blank?
      where('1=1')
    else
      where("complaints.date_received <= ?", Time.parse(to).end_of_day)
    end
  end

  def self.with_complainant_match(complainant_fragment)
    if complainant_fragment.blank?
      where("1=1")
    else
      sql = "\"complaints\".\"firstName\" || ' ' || \"complaints\".\"lastName\" ~* '.*#{complainant_fragment}.*'"
      where(sql)
    end
  end

  def self.index_page_associations(ids, query)
    filtered(query).
      includes({:assigns => :assignee},
        :mandate,
        {:status_changes => [:user, :complaint_status]},
        {:complaint_complaint_areas=>:complaint_area},
        {:complaint_agencies => :agency},
        {:communications => [:user, :communication_documents, :communicants]},
        :complaint_documents,
        {:reminders => :user},
        {:notes =>[:author, :editor]}).
      where(id: ids)
  end

  def self.with_case_reference_match(case_ref_fragment)
    sql = CaseReference.sql_match(case_ref_fragment)
    where(sql)
  end

  # can take either an array of strings or symbols
  # or cant take a single string or symbol
  def self.with_status(status_ids)
    joins(:status_changes => :complaint_status).
      merge(StatusChange.most_recent_for_complaint).
      merge(ComplaintStatus.with_status(status_ids))
  end

  def self.for_assignee(user_id = nil)
    user_id && !user_id.blank? ?
      select('distinct complaints.id, complaints.*, assigns.created_at, assigns.user_id, assigns.complaint_id').joins(:assigns).merge(Assign.most_recent_for_assignee(user_id)) :
      where("1=0")
  end

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
      complaint.date_received = Time.current
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
                        :mandate_id,
                        :area_ids,
                        :subarea_ids,
                        :area_subarea_ids,
                        :agency_ids,
                        :status_changes,
                        :communications])
  end


  # supports the checkbox selectors for areas and subareas
  alias_method :area_ids, :complaint_area_ids
  alias_method :subarea_ids, :complaint_subarea_ids
  alias_method :subarea_ids=, :complaint_subarea_ids=

  #used for testing
  def good_governance_subareas
    complaint_subareas.good_governance
  end
  #used for testing
  def human_rights_subareas
    complaint_subareas.human_rights
  end
  #used for testing
  def special_investigations_unit_subareas
    complaint_subareas.special_investigations_unit
  end

  # facilitates rendering of areas/subareas for a single complaint
  def area_subarea_ids
    complaint_subareas.inject({}) do |hash, subarea|
      area_id = subarea.area_id
      hash[area_id] = hash[area_id] || []
      hash[area_id] << subarea.id
      hash
    end
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
    status_changes.sort_by(&:change_date).last.complaint_status.name
  end

  def current_status_humanized
    status_changes.sort_by(&:change_date).last.status_humanized unless status_changes.empty?
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
