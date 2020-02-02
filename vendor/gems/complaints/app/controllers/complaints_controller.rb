class ComplaintsController < ApplicationController
  def index
    # normally this would not happen, but it happens in testing and perhaps might happen
    # in unforeseen circumstances?
    if params.keys.without("controller", "action", "locale").empty?
      redirect_to complaints_path('en',default_params) and return
    end
    logger.info "PARAMS #{index_query_params.inspect}"
    complaints = Complaint.index_page_associations(index_query_params)
    logger.info "complaints length: #{complaints.length}"

    #@selected_status_ids = default_params[:selected_status_ids]
    #@selected_assignee_id = current_user.id

    # filter controls dropdown options:
    # TODO looks like some redundancy can be exploited here:
    @complaint_areas = ComplaintArea.all.sort_by(&:name)
    @areas = ComplaintArea.all

    @subareas = ComplaintSubarea.all
    @statuses = ComplaintStatus.select(:id, :name).all
    @agencies = Agency.unassigned_first

    # TODO looks like some redundancy can be exploited here:
    @users = User.all
    @staff = User.order(:lastName,:firstName).select(:id,:firstName,:lastName)

    @filter_criteria = default_params
    @complaints = "[#{complaints.map(&:to_json).join(", ").html_safe}]".html_safe

    @maximum_filesize = ComplaintDocument.maximum_filesize * 1000000
    @permitted_filetypes = ComplaintDocument.permitted_filetypes
    @communication_maximum_filesize    = CommunicationDocument.maximum_filesize * 1000000
    @communication_permitted_filetypes = CommunicationDocument.permitted_filetypes
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
    params[:complaint][:status_changes_attributes][0][:user_id] = current_user.id
    if complaint.update(complaint_params)
      complaint.heading= t('.heading', case_reference: complaint.case_reference)
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
    populate_associations
    @complaint = Complaint.find(params[:id])
    @title = t('.heading', case_reference: @complaint.case_reference)
    @type = @complaint.type_as_symbol
    @edit = false
    @mode = "show"
    respond_to do |format|
      format.docx do
        send_file ComplaintReport.new(@complaint,current_user).docfile
      end
      format.html do
        render :complaint, :layout => 'application_webpack'
      end
    end
  end

  def new
    populate_associations
    @type = params[:type]
    @complaint = Complaint.new
    @edit = true
    @mode = "register"
    @title = t('.heading', type: params[:type].titlecase)
    render :complaint, :layout => 'application_webpack'
  end

  def create
    params[:complaint].delete(:close_memo) # not pertinent to new complaint, but supplied as 'undefined' by the client
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
  def populate_associations
    @areas = ComplaintArea.all
    @subareas = ComplaintSubarea.all
    @agencies = Agency.all
    @staff = User.order(:lastName,:firstName).select(:id,:firstName,:lastName)
    @maximum_filesize = ComplaintDocument.maximum_filesize * 1000000
    @permitted_filetypes = ComplaintDocument.permitted_filetypes
    @communication_maximum_filesize    = CommunicationDocument.maximum_filesize * 1000000
    @communication_permitted_filetypes = CommunicationDocument.permitted_filetypes
    @statuses = ComplaintStatus.ordered.select(:id, :name).all
    @office_groups = OfficeGroup.regional_provincial
    @branches = Office.branches
    @close_memo_options = ComplaintStatus::CloseMemoOptions
  end

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
                                       :organization_name, :organization_registration_number,
                                       :subarea_ids => [],
                                       :status_changes_attributes => [:user_id, :complaint_status_id, :close_memo],
                                       :agency_ids => [],
                                       :complaint_documents_attributes => [:file, :title, :original_filename, :original_type, :filesize, :lastModifiedDate],
                                     )
  end
end

