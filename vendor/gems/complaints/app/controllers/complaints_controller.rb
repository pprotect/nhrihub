class ComplaintsController < ApplicationController
  def index
    logger.info "PARAMS #{index_query_params.inspect}"
    #cache_fetcher = BulkCacheFetcher.new(Rails.cache)
    #complaints = cache_fetcher.fetch(Complaint.cache_identifiers(current_user)) do |uncached_keys_and_ids|
      #ids = uncached_keys_and_ids.values
      #Complaint.index_page_associations(current_user, ids).map(&:to_json)
    #end
    complaints = Complaint.index_page_associations(index_query_params)
    logger.info "complaints length: #{complaints.length}"

    @areas = ComplaintArea.all
    @subareas = ComplaintSubarea.all
    @selected_status_ids = default_params[:selected_status_ids]
    @selected_assignee_id = current_user.id
    @complaint_areas = ComplaintArea.all.sort_by(&:name)
    @filter_criteria = {
      complainant: nil,
      from: nil,
      to: nil,
      case_reference: nil,
      village: nil,
      phone: nil,
      selected_agency_ids: Agency.unscoped.pluck(:id),
      selected_assignee_id: @selected_assignee_id,
      selected_subarea_ids: @subareas.map(&:id),
      selected_status_ids: @selected_status_ids,
      selected_complaint_area_ids: @complaint_areas.map(&:id)
    }
    @complaints = "[#{complaints.map(&:to_json).join(", ").html_safe}]".html_safe

    @agencies = Agency.unassigned_first
    #@complaint_bases = [ StrategicPlans::ComplaintBasis.named_list,
                         #GoodGovernance::ComplaintBasis.named_list,
                         #Nhri::ComplaintBasis.named_list,
                         #Siu::ComplaintBasis.named_list ]
    @users = User.all
    #@good_governance_complaint_bases = GoodGovernance::ComplaintBasis.all
    #@human_rights_complaint_bases = Nhri::ComplaintBasis.all
    #@special_investigations_unit_complaint_bases = Siu::ComplaintBasis.all
    @staff = User.order(:lastName,:firstName).select(:id,:firstName,:lastName)
    #@maximum_filesize = ComplaintDocument.maximum_filesize * 1000000
    #@permitted_filetypes = ComplaintDocument.permitted_filetypes
    #@communication_maximum_filesize    = CommunicationDocument.maximum_filesize * 1000000
    #@communication_permitted_filetypes = CommunicationDocument.permitted_filetypes
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
    @complaint = Complaint.new(complaint_params)
    @complaint.status_changes_attributes = [{:user_id => current_user.id, :name => "Under Evaluation"}]
    if @complaint.save
      #render :json => complaint, :status => 200
      render @complaint, :status => 200
    else
      render :plain => @complaint.errors.full_messages, :status => 500
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
    @areas = ComplaintArea.all
    @subareas = ComplaintSubarea.all
    @agencies = Agency.unscoped.all
    @staff = User.order(:lastName,:firstName).select(:id,:firstName,:lastName)
    respond_to do |format|
      format.docx do
        send_file ComplaintReport.new(@complaint,current_user).docfile
      end
      format.html do
        render :show, :layout => 'application_webpack'
      end
    end
  end

  def new
    @title = t('.heading', type: params[:type].titlecase)
    @areas = ComplaintArea.all
    @subareas = ComplaintSubarea.all
    @agencies = Agency.all
    @complaint_bases = [ StrategicPlans::ComplaintBasis.named_list,
                         GoodGovernance::ComplaintBasis.named_list,
                         Nhri::ComplaintBasis.named_list,
                         Siu::ComplaintBasis.named_list ]
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
    render :new, :layout => 'application_webpack'
  end

  private
  def default_params
    Complaint.default_index_query_params(current_user.id)
    #{selected_assignee_id: current_user.id,
     #selected_status_ids: ComplaintStatus.default.map(&:id),
     #selected_complaint_area_ids: ComplaintArea.pluck(:id),
     #selected_subarea_ids: ComplaintSubarea.pluck(:id),
     #selected_agency_ids: Agency.unscoped.pluck(:id) }
  end

  def index_query_params
    params.
      permit(:complainant, :from, :to, :case_reference, :village, :phone,
             :selected_assignee_id, :locale, :mandate_id, :type,
             :selected_status_ids => [], :selected_complaint_area_ids => [],
             :selected_subarea_ids => [],
             :selected_agency_ids => [] ).
      with_defaults(default_params).
      slice(:selected_assignee_id, :selected_status_ids, :complainant,
            :from, :to, :village, :phone, :selected_complaint_area_ids,
            :selected_subarea_ids, :case_reference,
            :selected_agency_ids )
  end

  def complaint_params
    params.require(:complaint).permit( :firstName, :lastName, :title, :village, :phone, :new_assignee_id,
                                       :dob, :email, :complained_to_subject_agency, :desired_outcome, :gender, :details,
                                       :date, :imported, :complaint_area_id,
                                       :subarea_ids => [],
                                       :status_changes_attributes => [:user_id, :name],
                                       :agency_ids => [],
                                       :complaint_documents_attributes => [:file, :title, :original_filename, :original_type, :filesize, :lastModifiedDate],
                                     )
  end
end

