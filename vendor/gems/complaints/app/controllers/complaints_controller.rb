class ComplaintsController < ApplicationController
  def index
    logger.info "PARAMS #{index_query_params.inspect}"
    #cache_fetcher = BulkCacheFetcher.new(Rails.cache)
    #complaints = cache_fetcher.fetch(Complaint.cache_identifiers(current_user)) do |uncached_keys_and_ids|
      #ids = uncached_keys_and_ids.values
      #Complaint.index_page_associations(current_user, ids).map(&:to_json)
    #end
    complaints = Complaint.index_page_associations(Complaint.pluck(:id), index_query_params)

    @selected_status_ids = index_query_params[:selected_status_ids]
    @selected_assignee_id = index_query_params[:selected_assignee_id]
    @mandates = Mandate.all.sort_by(&:name)
    @filter_criteria = {
      complainant: "",
      from: nil,
      to: nil,
      case_reference: params[:case_reference],
      village: nil,
      phone_number: "",
      basis_ids: [],
      selected_agency_ids: Agency.pluck(:id),
      current_assignee_id: 0,
      selected_assignee_id: @selected_assignee_id,
      selected_human_rights_complaint_basis_ids: index_query_params[:selected_human_rights_complaint_basis_ids],
      selected_special_investigations_unit_complaint_basis_ids: index_query_params[:selected_special_investigations_unit_complaint_basis_ids],
      selected_good_governance_complaint_basis_ids: index_query_params[:selected_good_governance_complaint_basis_ids],
      selected_status_ids: @selected_status_ids,
      selected_mandate_ids: @mandates.pluck(:id)
    }
    @complaints = "[#{complaints.map(&:to_json).join(", ").html_safe}]".html_safe

    @agencies = Agency.all
    @complaint_bases = [ StrategicPlans::ComplaintBasis.named_list,
                         GoodGovernance::ComplaintBasis.named_list,
                         Nhri::ComplaintBasis.named_list,
                         Siu::ComplaintBasis.named_list ]
    @next_case_reference = Complaint.next_case_reference
    @users = User.all
    @good_governance_complaint_bases = GoodGovernance::ComplaintBasis.all
    @human_rights_complaint_bases = Nhri::ComplaintBasis.all
    @special_investigations_unit_complaint_bases = Siu::ComplaintBasis.all
    @staff = User.order(:lastName,:firstName).select(:id,:firstName,:lastName)
    @maximum_filesize = ComplaintDocument.maximum_filesize * 1000000
    @permitted_filetypes = ComplaintDocument.permitted_filetypes
    @communication_maximum_filesize    = CommunicationDocument.maximum_filesize * 1000000
    @communication_permitted_filetypes = CommunicationDocument.permitted_filetypes
    @statuses = ComplaintStatus.select(:id, :name).all
    respond_to do |format|
      format.json do
        render :json => complaints
      end
      format.html do
        render :index, :layout => 'application_webpack'
      end
      format.docx do
        send_file ComplaintsReport.new(Complaint.all).docfile
      end
    end
  end

  def create
    params[:complaint].delete(:current_status_humanized)
    complaint = Complaint.new(complaint_params)
    complaint.status_changes_attributes = [{:user_id => current_user.id, :name => "Under Evaluation"}]
    if complaint.save
      render :json => complaint, :status => 200
    else
      render :plain => complaint.errors.full_messages, :status => 500
    end
  end

  def update
    complaint = Complaint.find(params[:id])
    params[:complaint][:status_changes_attributes] = [{:user_id => current_user.id, :name => params[:complaint].delete(:current_status_humanized)}]
    if complaint.update(complaint_params)
      render :json => complaint, :status => 200
    else
      head :internal_server_error
    end
  rescue => e
    logger.error e
    head :internal_server_error
  end

  def destroy
    complaint = Complaint.find(params[:id])
    complaint.destroy
    head :ok
  end

  def show
    @complaint = Complaint.find(params[:id])
    respond_to do |format|
      format.docx do
        send_file ComplaintReport.new(@complaint,current_user).docfile
      end
    end
  end

  private
  def default_params
    {selected_assignee_id: current_user.id,
     selected_status_ids: ComplaintStatus.default.map(&:id),
     selected_mandate_ids: Mandate.pluck(:id),
     selected_special_investigations_unit_complaint_basis_ids: Siu::ComplaintBasis.pluck(:id),
     selected_human_rights_complaint_basis_ids: Nhri::ComplaintBasis.pluck(:id),
     selected_good_governance_complaint_basis_ids: GoodGovernance::ComplaintBasis.pluck(:id)}
  end

  def index_query_params
    params.
      permit(:complainant, :from, :to, :case_reference, :village, :phone_number, :phone,
             :current_assignee_id, :selected_assignee_id, :locale, :mandate_id,
             :selected_status_ids => [], :selected_mandate_ids => [],
             :selected_special_investigations_unit_complaint_basis_ids => [],
             :selected_human_rights_complaint_basis_ids => [],
             :selected_good_governance_complaint_basis_ids => [] ).
      with_defaults(default_params).
      slice(:selected_assignee_id, :selected_status_ids, :case_reference, :complainant,
            :from, :to, :village, :phone, :selected_mandate_ids,
            :selected_special_investigations_unit_complaint_basis_ids,
            :selected_human_rights_complaint_basis_ids,
            :selected_good_governance_complaint_basis_ids)
  end

  def complaint_params
    params.require(:complaint).permit( :case_reference, :firstName, :lastName, :chiefly_title, :village, :phone, :new_assignee_id,
                                       :dob, :email, :complained_to_subject_agency, :desired_outcome, :gender, :details,
                                       :date, :imported, :mandate_id, :good_governance_complaint_basis_ids => [],
                                       :special_investigations_unit_complaint_basis_ids => [],
                                       :human_rights_complaint_basis_ids => [],
                                       :status_changes_attributes => [:user_id, :name],
                                       :agency_ids => [],
                                       :complaint_documents_attributes => [:file, :title, :original_filename, :original_type, :filesize, :lastModifiedDate],
                                     )
  end
end

