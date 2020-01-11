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
      from: "",
      to: "",
      case_reference: nil,
      city: nil,
      phone: "",
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

  def update
    params[:complaint].delete(:type) # ignore type on update... it will be correct
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
    @type = @complaint.complaint_type.split(' ').first.downcase
    @areas = ComplaintArea.all
    @subareas = ComplaintSubarea.all
    @agencies = Agency.unscoped.all
    @staff = User.order(:lastName,:firstName).select(:id,:firstName,:lastName)
    @maximum_filesize = ComplaintDocument.maximum_filesize * 1000000
    @permitted_filetypes = ComplaintDocument.permitted_filetypes
    @communication_maximum_filesize    = CommunicationDocument.maximum_filesize * 1000000
    @communication_permitted_filetypes = CommunicationDocument.permitted_filetypes
    @statuses = ComplaintStatus.select(:id, :name).all
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
    @type = params[:type]
    @title = t('.heading', type: params[:type].titlecase)
    @areas = ComplaintArea.all
    @subareas = ComplaintSubarea.all
    @agencies = Agency.all
    #@complaint_bases = [ StrategicPlans::ComplaintBasis.named_list,
                         #GoodGovernance::ComplaintBasis.named_list,
                         #Nhri::ComplaintBasis.named_list,
                         #Siu::ComplaintBasis.named_list ]
    @users = User.all
    #@good_governance_complaint_bases = GoodGovernance::ComplaintBasis.all
    #@human_rights_complaint_bases = Nhri::ComplaintBasis.all
    #@special_investigations_unit_complaint_bases = Siu::ComplaintBasis.all
    @staff = User.order(:lastName,:firstName).select(:id,:firstName,:lastName)
    @maximum_filesize = ComplaintDocument.maximum_filesize * 1000000
    @permitted_filetypes = ComplaintDocument.permitted_filetypes
    @communication_maximum_filesize    = CommunicationDocument.maximum_filesize * 1000000
    @communication_permitted_filetypes = CommunicationDocument.permitted_filetypes
    @statuses = ComplaintStatus.select(:id, :name).all
    render :new, :layout => 'application_webpack'
  end

  def create
    type = params[:complaint].delete(:type)               # individual, organization, own_motion
    klass = "#{type}_complaint".classify.constantize      # IndividualComplaint, OrganizationComplaint, OwnMotionComplaint
    @complaint = klass.send(:new, complaint_params)       # e.g. IndividualComplaint.new(complaint_params)
    @complaint.assign_initial_status(current_user)
    if @complaint.save
      # piggy back the page heading on the complaint object
      # TODO maybe not the best way... create it dynamically in the client?
      @complaint.heading = t('.show.heading',case_reference: @complaint.case_reference)
      render json: @complaint, status: 200
    else
      render :plain => @complaint.errors.full_messages, :status => 500
    end
  end

  private
  def default_params
    Complaint.default_index_query_params(current_user.id)
  end

  def index_query_params
    params.
      permit(:complainant, :from, :to, :case_reference, :city, :phone,
             :selected_assignee_id, :locale, :mandate_id, :type,
             :selected_status_ids => [], :selected_complaint_area_ids => [],
             :selected_subarea_ids => [],
             :selected_agency_ids => [] ).
      with_defaults(default_params).
      slice(:selected_assignee_id, :selected_status_ids, :complainant,
            :from, :to, :city, :phone, :selected_complaint_area_ids,
            :selected_subarea_ids, :case_reference,
            :selected_agency_ids )
  end

  def complaint_params
    params.require(:complaint).permit( :firstName, :lastName, :title, :city, :home_phone, :new_assignee_id,
                                       :dob, :email, :complained_to_subject_agency, :desired_outcome, :gender, :details,
                                       :date, :imported, :complaint_area_id,
                                       :cell_phone, :fax, :province, :postal_code, :id_type, :id_value, :alt_id_type, :alt_id_value,
                                       :alt_id_other_type, :physical_address, :postal_address, :preferred_means,
                                       :subarea_ids => [],
                                       :status_changes_attributes => [:user_id, :name],
                                       :agency_ids => [],
                                       :complaint_documents_attributes => [:file, :title, :original_filename, :original_type, :filesize, :lastModifiedDate],
                                     )
  end
end

