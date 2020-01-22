class DuplicateComplaintsController < ApplicationController
  def index
    @duplicate_complaints = Complaint.possible_duplicates(complaint_duplicate_params)
    render json: @duplicate_complaints
  end

  def new
    populate_associations
    @type = params[:type]
    @complaint = Complaint.new
    @edit = true
    @mode = "intake"
    @title = t('.heading', type: params[:type].titlecase)
    render 'complaints/complaint', :layout => 'application_webpack'
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
    @statuses = ComplaintStatus.select(:id, :name).all
    @office_groups = OfficeGroup.regional_provincial
    @branches = Office.branches
  end

  def complaint_duplicate_params
    params.require(:match).permit(:type, :organization_name, :organization_registration_number,
                                  :id_value, :alt_id_value, :lastName, :email, :agency_ids => [])
  end
end

