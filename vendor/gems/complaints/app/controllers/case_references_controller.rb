class CaseReferencesController < ActionController::API
  def index
    CaseReference.find_all({refs: params[:dupe_refs].split(',')})
    render json: {case_references_exist: true}
  rescue ActiveRecord::RecordNotFound
    render json: {case_references_exist: false}
  end
end
