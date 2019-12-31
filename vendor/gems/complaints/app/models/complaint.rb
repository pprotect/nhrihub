#require Complaints::Engine.root.join('app', 'domain_models', 'cache')
#require 'case_reference'

class Complaint < ActiveRecord::Base
  #include Cache
  include Rails.application.routes.url_helpers
  belongs_to :complaint_area
  has_many :complaint_complaint_subareas, :dependent => :destroy
  has_many :complaint_subareas, :through => :complaint_complaint_subareas
  has_many :reminders, :as => :remindable, :autosave => true, :dependent => :destroy, :inverse_of => :remindable
  has_many :notes, :as => :notable, :autosave => true, :dependent => :destroy, :inverse_of => :notable
  has_many :assigns, :autosave => true, :dependent => :destroy, after_add: :notify_assignee
  has_many :assignees, :through => :assigns
  has_many :status_changes, :dependent => :destroy
  accepts_nested_attributes_for :status_changes
  has_many :complaint_statuses, :through => :status_changes
  has_many :complaint_agencies, :dependent => :destroy
  has_many :agencies, :through => :complaint_agencies
  has_many :complaint_documents, :dependent => :destroy
  accepts_nested_attributes_for :complaint_documents
  has_many :communications, :dependent => :destroy

  attr_accessor :witness_name

  # why after_commit iso after_create? see https://dev.mikamai.com/2016/01/19/postgresql-transaction-and-rails-callbacks/
  after_commit :generate_case_reference, on: :create
  serialize :case_reference, CaseReference

  def generate_case_reference
    update_column :case_reference, Complaint.next_case_reference
    # must be done after commit b/c case_reference is not final until the last commit
    assigns.last&.notify_assignee
  end

  def notify_assignee(assign)
    # i.e. when complaint is updated with a new assign
    assign.notify_assignee if assigns.size > 1
  end

  def self.default_index_query_params(user_id)
    { selected_assignee_id:        user_id,
      selected_status_ids:         ComplaintStatus.default.map(&:id),
      selected_complaint_area_ids: ComplaintArea.pluck(:id),
      selected_subarea_ids:        ComplaintSubarea.pluck(:id),
      selected_agency_ids:         Agency.unscoped.pluck(:id) }
  end

  def self.filtered(query)
      logger.info "for_assignee: #{for_assignee(query[:selected_assignee_id]).length}"
      logger.info "with_status: #{with_status(query[:selected_status_ids]).length}"
      logger.info "with_complaint_area_ids: #{with_complaint_area_ids(query[:selected_complaint_area_ids]).length}"
      logger.info "with_case_reference_match: #{with_case_reference_match(query[:case_reference]).length}"
      logger.info "with_complainant_match: #{with_complainant_match(query[:complainant]).length}"
      logger.info "since_date: #{since_date(query[:from]).length}"
      logger.info "before_date: #{before_date(query[:to]).length}"
      logger.info "with_village: #{with_village(query[:village]).length}"
      logger.info "with_phone: #{with_phone(query[:phone]).length}"
      logger.info "with_subareas: #{with_subareas(query[:selected_subarea_ids]).length}"
      logger.info "with_agencies: #{with_agencies(query[:selected_agency_ids]).length}"
    for_assignee(query[:selected_assignee_id]).
      with_status(query[:selected_status_ids]).
      with_complaint_area_ids(query[:selected_complaint_area_ids]).
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
    return no_filter if Agency.count.zero?
    selected_agency_ids = nil if selected_agency_ids.delete_if(&:blank?).empty?
    joins(:complaint_agencies).where("complaint_agencies.agency_id in (?)", selected_agency_ids)
  end

  def self.no_filter
    where("1=1")
  end

  def self.with_subareas(selected_subarea_ids)
    return no_filter if ComplaintSubarea.count.zero?
    selected_subarea_ids = nil if selected_subarea_ids.delete_if(&:blank?).empty?

    joins(:complaint_complaint_subareas).
      where( "complaint_complaint_subareas.subarea_id in (?)", selected_subarea_ids)
  end

  def self.with_complaint_area_ids(selected_complaint_area_ids)
    return no_filter if ComplaintArea.count.zero?
    where(complaint_area_id: selected_complaint_area_ids)
  end

  def self.with_phone(phone_fragment)
    digits = phone_fragment&.delete('^0-9')
    return no_filter if digits.nil? || digits.empty?
    where("complaints.phone ~ '.*#{digits}.*'")
  end

  def self.with_village(village_fragment)
    return no_filter if village_fragment.blank?
    where("\"complaints\".\"village\" ~* '.*#{village_fragment}.*'")
  end

  def self.since_date(from)
    return no_filter if from.blank?
    time_from = Time.zone.local_to_utc(Time.parse(from)).beginning_of_day
    where("complaints.date_received >= ?", time_from)
  end

  def self.before_date(to)
    return no_filter if to.blank?
    where("complaints.date_received <= ?", Time.parse(to).end_of_day)
  end

  def self.with_complainant_match(complainant_fragment)
    return no_filter if complainant_fragment.blank?
    sql = "\"complaints\".\"firstName\" || ' ' || \"complaints\".\"lastName\" ~* '.*#{complainant_fragment}.*'"
    where(sql)
  end

  def self.index_page_associations(query)
    filtered(query).
      includes({:assigns => :assignee},
        :complaint_area,
        {:status_changes => [:user, :complaint_status]},
        {:complaint_agencies => :agency},
        {:communications => [:user, :communication_documents, :communicants]},
        :complaint_documents,
        {:reminders => :user},
        {:notes =>[:author, :editor]})
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
    if complaint.agencies.empty?
      complaint.agencies << Agency.unscoped.find_or_create_by(name: "Unassigned")
    end
  end

  def <=>(other)
    case_reference <=> other.case_reference
  end

  def as_json(options = {})
    super( :except => [:case_reference_alt],
           :methods => [:reminders,
                        :notes,
                        :assigns,
                        :current_assignee_id,
                        :current_assignee_name,
                        :date,
                        :date_of_birth,
                        :dob,
                        :current_status_humanized,
                        :attached_documents,
                        :complaint_area_id,
                        :subarea_ids,
                        :area_subarea_ids,
                        :agency_ids,
                        :status_changes,
                        :communications])
  end


  # supports the checkbox selectors for subareas
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
    [title, firstName, lastName].join(' ')
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
