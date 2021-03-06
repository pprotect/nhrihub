#require Complaints::Engine.root.join('app', 'domain_models', 'cache')

class Complaint < ActiveRecord::Base
  #include Cache
  include ComplaintQuery
  DateFormat = "%d/%m/%Y"

  include Rails.application.routes.url_helpers
  belongs_to :complaint_area
  has_many :complaint_complaint_subareas, :dependent => :destroy
  has_many :complaint_subareas, :through => :complaint_complaint_subareas
  has_many :reminders, :as => :remindable, :autosave => true, :dependent => :destroy, :inverse_of => :remindable
  has_many :notes, :as => :notable, :autosave => true, :dependent => :destroy, :inverse_of => :notable
  has_many :assigns, :autosave => true, :dependent => :destroy, after_add: :notify_assignee
  accepts_nested_attributes_for :assigns
  has_many :assignees, :through => :assigns
  has_many :status_changes, :dependent => :destroy
  accepts_nested_attributes_for :status_changes
  has_many :complaint_statuses, :through => :status_changes
  has_many :complaint_agencies, :dependent => :destroy
  has_many :agencies, :through => :complaint_agencies
  has_many :complaint_documents, :dependent => :destroy
  accepts_nested_attributes_for :complaint_documents
  has_many :communications, :dependent => :destroy
  has_one :case_reference, :dependent => :destroy
  has_many :complaint_transfers
  has_many :transferees, through: :complaint_transfers, class_name: :Office, foreign_key: :office_id
  accepts_nested_attributes_for :complaint_transfers
  has_many :jurisdiction_assignments
  has_many :branches, -> { merge(Office.branches) }, class_name: "Office", through: :jurisdiction_assignments
  accepts_nested_attributes_for :jurisdiction_assignments
  has_many :complaint_legislations
  has_many :legislations, through: :complaint_legislations
  belongs_to :duplication_group, counter_cache: true
  belongs_to :linked_complaints_group, counter_cache: true
  has_and_belongs_to_many :complainants
  accepts_nested_attributes_for :complainants

  attr_accessor :witness_name, :heading

  after_create :generate_case_reference

  def dupe_refs=(refs)
    refs = refs.split(', ') if refs.is_a? String
    complaints = CaseReference.find_all(refs: refs).map(&:complaint)
    group_id = DuplicationGroup.create.id
    previous_duplicates = duplicates
    (complaints + complaints.map(&:duplicates)).flatten.each do |complaint|
      complaint.update(duplication_group_id: group_id)
    end
    if persisted?
      update(duplication_group_id: group_id)
      DuplicationGroup.cleanup
    else
      self.duplication_group_id = group_id
    end
  end

  def duplicates
    return [] if duplication_group_id.nil?
    DuplicateComplaint.where("duplication_group_id = ? and id != ?", duplication_group_id, id)
  end

  def duplicates=(dupe_array)
    self.dupe_refs = dupe_array.reject(&:blank?).map{|dr| dr[:case_reference]}
  end

  def link_refs=(refs)
    refs = refs.split(', ') if refs.is_a? String
    complaints = CaseReference.find_all(refs: refs).map(&:complaint)
    group_id = LinkedComplaintsGroup.create.id
    previous_linked_complaints = linked_complaints
    (complaints + complaints.map(&:linked_complaints)).flatten.each do |complaint|
      complaint.update(linked_complaints_group_id: group_id)
    end
    if persisted?
      update(linked_complaints_group_id: group_id)
      LinkedComplaintsGroup.cleanup
    else
      self.linked_complaints_group_id = group_id
    end
  end

  def linked_complaints
    return [] if linked_complaints_group_id.nil?
    LinkedComplaint.where("linked_complaints_group_id = ? and id != ?", linked_complaints_group_id, id)
  end

  def linked_complaints=(link_array)
    self.link_refs = link_array.reject(&:blank?).map{|dr| dr[:case_reference]}
  end

  def generate_case_reference
    self.case_reference = CaseReference.create
  end

  def assign_initial_status(user)
    self.status_changes_attributes = [{:user_id => user.id, :name => self.class::InitialStatus }]
  end

  def notify_assignee(assign)
    # i.e. when complaint is updated with a new assign
    assign.notify_assignee if assigns.size > 1 && persisted?
  end

  def self.default_index_query_params(user_id)
    {
      complainant: "",
      from: "",
      to: "",
      case_reference: "",
      city: "",
      phone: "",
      selected_assignee_id:        user_id,
      selected_status_ids:         ComplaintStatus.default.map(&:id),
      selected_complaint_area_ids: ComplaintArea.pluck(:id),
      selected_subarea_ids:        ComplaintSubarea.pluck(:id),
      selected_agency_id:         "all",
      selected_office_id: ""}
  end

  def self.filtered(selected_assignee_id:,selected_status_ids:,selected_complaint_area_ids:,case_reference:,complainant:,from:,to:,city:,phone:,selected_subarea_ids:,selected_agency_id:,selected_office_id:)
    # just for debugging
    if ENV['log_filter'] == 'true'
      puts [selected_assignee_id, selected_status_ids, complainant, from, to,
       city, phone, selected_complaint_area_ids, selected_subarea_ids,
       case_reference, selected_agency_id, selected_office_id].inspect
      logger.info "for_assignee: #{for_assignee(selected_assignee_id).length}"
      logger.info "with_status: #{with_status(selected_status_ids).length}"
      logger.info "with_complaint_area_ids: #{with_complaint_area_ids(selected_complaint_area_ids).length}"
      logger.info "with_case_reference_match: #{with_case_reference_match(case_reference).length}"
      logger.info "with_complainant_fragment_match: #{with_complainant_fragment_match(complainant).length}"
      logger.info "since_date: #{since_date(from).length}"
      logger.info "before_date: #{before_date(to).length}"
      logger.info "with_city: #{with_city(city).length}"
      logger.info "with_phone: #{with_phone(phone).length}"
      logger.info "with_subareas: #{with_subareas(selected_subarea_ids).length}"
      logger.info "with_agencies: #{with_agencies(selected_agency_id).length}"
      logger.info "transferred_to: #{transferred_to(selected_office_id).length}"
    end

    res = select("DISTINCT ON (complaints.id) complaints.*").
      for_assignee(selected_assignee_id).
      with_status(selected_status_ids).
      with_complaint_area_ids(selected_complaint_area_ids).
      with_case_reference_match(case_reference).
      with_complainant_fragment_match(complainant).
      since_date(from).
      before_date(to).
      with_city(city).
      with_phone(phone).
      with_subareas(selected_subarea_ids).
      with_agencies(selected_agency_id).
      transferred_to(selected_office_id)
  end

  def self.index_page_associations(query)
    query = query.to_h.symbolize_keys
    filtered(query).
      includes({:assigns => :assignee},
        :complaint_area,
        {:status_changes => [:user, :complaint_status]},
        {:complaint_agencies => :agency},
        {:communications => [:user, :communication_documents, :communicants]},
        :complaint_documents,
        {:reminders => :user},
        {:notes =>[:author, :editor]}).
      sort_by(&:case_reference)
  end

  def status_changes_attributes=(attrs)
    # only create a status_change object if this is a new complaint
    # or if the status is changing
    attrs = attrs[0]
    attrs.symbolize_keys
    change_date = attrs[:change_date].nil? ? DateTime.now : Date.parse(attrs[:change_date]).to_datetime
    user_id = attrs[:user_id]
    if !persisted?
      complaint_status = ComplaintStatus.find_or_create_by(:name => self.class::InitialStatus )
      complaint_status_id = complaint_status.id
      status_changes.build({:user_id => user_id,
                            :change_date => change_date,
                            :complaint_status_id => complaint_status_id})
    elsif !(attrs[:complaint_status_id].nil? || attrs[:complaint_status_id] == "null" || attrs[:complaint_status_id] == 'undefined') && 
           ((attrs[:complaint_status_id].to_i != status_id) ||
            ((attrs[:complaint_status_id].to_i == status_id) && (attrs[:status_memo] != current_status.status_memo )))
      status_memo = attrs[:status_memo]=='undefined' ? nil : attrs[:status_memo]
      sc = status_changes.build({:user_id => user_id,
                            :change_date => change_date,
                            :complaint_status_id => attrs[:complaint_status_id],
                            :status_memo => status_memo,
                            :status_memo_type => attrs[:status_memo_type]})
    end
  end

  before_save FormDataSanitize

  before_create do |complaint|
    if complaint.date_received.nil? || complaint.date_received == "undefined" || complaint.date_received == "null"
      complaint.date_received = Time.current
    end
    if complaint.agencies.empty?
      complaint.agencies << Agency.unscoped.find_or_create_by(name: "Unassigned")
    end
  end

  def complainants_attributes=(array_of_attrs)
    sanitized_attrs = array_of_attrs.each do |attrs|
      attrs.delete("id") if attrs["id"] == "null" # formData designates null/nil with "null"
    end
    super sanitized_attrs
  end
  alias_method :complainants=, :complainants_attributes=
  #alias_method :complainants_attributes, :complainants

  def <=>(other)
    case_reference <=> other.case_reference
  end

  def complaint_type
    type&.underscore&.humanize
  end

  def type_as_symbol
    type.gsub(/Complaint$/,'').underscore
  end

  def timeline_events
    [status_changes, complaint_transfers, jurisdiction_assignments, assigns].
      flatten.
      map(&:as_timeline_event).
      sort_by(&:date).
      reverse
  end

  def as_json(options = {})
    # these fields are included in options when json: complaint is called in a controller
    if options.except(:status, :prefixes, :template, :layout).blank?
      options = { :methods => [ :agencies,
                                #:agency_ids,
                                :area_subarea_ids,
                                :assigns,
                                :attached_documents,
                                :case_reference,
                                :communications,
                                :complainants,
                                :complaint_area_id,
                                :complaint_type,
                                :current_assignee_id,
                                :current_assignee_name,
                                :current_status,
                                :date,
                                :duplicates,
                                :heading,
                                :legislation_ids,
                                :linked_complaints,
                                :notes,
                                :reminders,
                                :status_id,
                                :subarea_ids,
                                :timeline_events,
                                :type_as_symbol ] }
    end
    super(options)
  end

  def assigns
    Assign.where(complaint_id: id).order("assigns.created_at DESC")
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

  def attached_documents
    complaint_documents
  end

  def closed?
    !current_status
  end

  def status_id
    current_status&.complaint_status&.id
  end

  def current_status
    status_changes.sort_by(&:change_date).last
  end

  def current_event_description
    current_status.event_description
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
    date_received.strftime(DateFormat) unless date_received.nil?
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
    @current_assignee ||= assigns.single_complaint_most_recent.first.assignee unless assigns.empty?
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

  def url
    complaint_url('en', {:host => SITE_URL, :protocol => 'https', :id => id})
  end
  alias_method :index_url, :url # only for conformity wih the reminder convention

end
