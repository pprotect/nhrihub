class ComplaintAdminController < ApplicationController
  def show
    @provinces = Province.order(:name).select(:name, :id).to_json
    @agency = Agency.new
    @agency_groups = Agency.hierarchy.to_json
    @legislation = Legislation.new
    @legislations = Legislation.all.to_json(only: [:short_name, :full_name, :id], methods: [:delete_allowed])
    @complaint_document_filetypes = ComplaintDocument.permitted_filetypes
    @complaint_filetype = Filetype.new
    @complaint_filesize = ComplaintDocument.maximum_filesize
    @communication_document_filetypes = CommunicationDocument.permitted_filetypes
    @communication_filetype = Filetype.new
    @communication_filesize = CommunicationDocument.maximum_filesize
    @good_governance_complaint_basis = GoodGovernance::ComplaintBasis.new
    @good_governance_complaint_bases = GoodGovernance::ComplaintBasis.pluck(:name)
    @siu_complaint_basis = Siu::ComplaintBasis.new
    @siu_complaint_bases = Siu::ComplaintBasis.pluck(:name)
    @strategic_plan_complaint_basis = StrategicPlans::ComplaintBasis.new
    @strategic_plan_complaint_bases = StrategicPlans::ComplaintBasis.pluck(:name)
    @areas = ComplaintArea.all
    @create_subarea_url = complaint_area_subareas_path(I18n.locale, "area_id")
    @create_area_url = complaint_areas_path(I18n.locale)
    @office_groups = OfficeGroup.all
    @create_office_url = office_group_office_index_path("office_group_id")
    @create_office_group_url = office_group_index_path
  end
end
