class MediaAppearancesController < ApplicationController
  include AttachedFile

  def index
    @media_appearances = MediaAppearance.includes(:subareas, :performance_indicators, :notes, :reminders, :areas => :subareas).all
    @media_appearance = MediaAppearance.new
    @areas = Area.includes(:subareas).all
    @subareas = Subarea.extended
    @planned_results = PlannedResult.all_with_associations
  end

  def create
    ma = MediaAppearance.new(media_appearance_params)
    if ma.save
      render :json => ma, :status => 200
    else
      head :internal_server_error
    end
  end

  def destroy
    media_appearance = MediaAppearance.find(params[:id])
    media_appearance.destroy
    head :ok
  end

  def update
    media_appearance = MediaAppearance.find(params[:id])
    media_appearance.update(media_appearance_params)
    render :json => media_appearance, :status => 200
  end

  def show
    send_blob MediaAppearance.find(params[:id])
  end

  private
  def media_appearance_params
    if !(params[:media_appearance][:article_link].blank? || params[:media_appearance][:article_link] == "null") || params[:media_appearance][:file] == "_remove"
      params["media_appearance"]["original_filename"] = nil
      params["media_appearance"]["filesize"] = nil
      params["media_appearance"]["original_type"] = nil
      params["media_appearance"]["remove_file"] = true
      params["media_appearance"].delete("file")
    end
    params["media_appearance"]["user_id"] = current_user.id
    params.
      require(:media_appearance).
      permit(:title,
             :file,
             :remove_file,
             :original_filename,
             :filesize,
             :original_type,
             :lastModifiedDate,
             :article_link,
             :user_id,
             :performance_indicator_associations_attributes => [:association_id, :performance_indicator_id],
             :area_ids => [],
             :subarea_ids => [])
  end

end
