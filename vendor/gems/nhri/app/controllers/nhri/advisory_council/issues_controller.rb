class Nhri::AdvisoryCouncil::IssuesController < ApplicationController
  include AttachedFile

  def index
    @advisory_council_issues = Nhri::AdvisoryCouncil::AdvisoryCouncilIssue.includes(:advisory_council_issue_subareas, :notes, :reminders, :advisory_council_issue_areas => :advisory_council_issue_subareas)
    @areas = Nhri::AdvisoryCouncil::AdvisoryCouncilIssueArea.includes(:advisory_council_issue_subareas).all
    @subareas = Nhri::AdvisoryCouncil::AdvisoryCouncilIssueSubarea.extended
    @advisory_council_issue = Nhri::AdvisoryCouncil::AdvisoryCouncilIssue.new
    @all_mandates = Mandate.all
    respond_to do |format|
      format.html
      format.docx do
        send_file IssuesReport.new(@advisory_council_issues).docfile
      end
    end
  end

  def create
    issue = Nhri::AdvisoryCouncil::AdvisoryCouncilIssue.new(issue_params)
    if issue.save
      render :json => issue, :status => 200
    else
      head :internal_server_error
    end
  end

  def destroy
    issue = Nhri::AdvisoryCouncil::AdvisoryCouncilIssue.find(params[:id])
    issue.destroy
    head :ok
  end

  def update
    issue = Nhri::AdvisoryCouncil::AdvisoryCouncilIssue.find(params[:id])
    issue.update(issue_params)
    render :json => issue, :status => 200
  end

  def show
    send_blob( Nhri::AdvisoryCouncil::AdvisoryCouncilIssue.find(params[:id]))
  end

  private
  def issue_params
    if params[:advisory_council_issue][:file] == "_remove"
      params[:advisory_council_issue].delete(:file)
      params["advisory_council_issue"]["original_filename"] = nil
      params["advisory_council_issue"]["filesize"] = nil
      params["advisory_council_issue"]["original_type"] = nil
      params[:advisory_council_issue][:remove_file] = true
    end
    params[:advisory_council_issue][:advisory_council_issue_area_ids] = params[:advisory_council_issue].delete(:area_ids)
    params[:advisory_council_issue][:advisory_council_issue_subarea_ids] = params[:advisory_council_issue].delete(:subarea_ids)
    params["advisory_council_issue"]["user_id"] = current_user.id
    params.
      require(:advisory_council_issue).
      permit(:title,
             :file,
             :remove_file,
             :original_filename,
             :filesize,
             :original_type,
             :lastModifiedDate,
             :user_id,
             :article_link,
             :mandate_id,
             :performance_indicator_ids => [], # it's from shared js and it's ignored
             :advisory_council_issue_area_ids => [],
             :advisory_council_issue_subarea_ids => [])
  end

end
