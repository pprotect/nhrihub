class InternalDocumentsController < ApplicationController
  include AttachedFile
  def index
    @internal_document = InternalDocument.new
    @internal_documents = DocumentGroup.non_empty.map(&:primary) # all types of InternalDocument
    @required_files_titles = AccreditationDocumentGroup.all.map(&:id_and_title)
  end

  def create
    params["internal_document"]["user_id"] = current_user.id
    params[:internal_document][:type] = "AccreditationRequiredDoc" if accreditation_type
    model = params[:internal_document][:type].constantize
    @internal_document = model.create(doc_params)
    render :json => {:file => @internal_document.document_group.primary, :required_files_titles => AccreditationDocumentGroup.all.map(&:id_and_title) }
  end

  def destroy
    doc = InternalDocument.find(params[:id])
    document_group_id = doc.document_group_id
    doc.destroy
    if DocumentGroup.exists?(document_group_id) && !DocumentGroup.find(document_group_id).empty?
      internal_document = DocumentGroup.find(document_group_id).primary
      render :json => internal_document, :status => 200
    else # no doc group (last non-icc file was deleted) or last icc file was deleted
      head :reset_content
    end
  end

  # update invoked for updating the original_filename and/or revision
  # also invoked for adding replacing a file... updating the document group
  def update
    internal_document = InternalDocument.find(params[:id])
    if accreditation_type
      internal_document.becomes(AccreditationRequiredDoc)
    end
    if internal_document.update(doc_params)
      # return the primary, even if we're updating an archive doc
      @internal_document = internal_document.document_group_primary
      render :json => @internal_document, :status => 200
    else
      head :internal_server_error
    end
  end

  def show
    send_blob(InternalDocument.find(params[:id]))
  end

  private
  def doc_params
    attrs = [:title, :revision, :file, :original_filename,
             :original_type, :lastModifiedDate, :filesize,
             :document_group_id, :user_id, :type]

    params.
      require(:internal_document).
      #permit(*attrs, :archive_files =>[*attrs])
      permit(*attrs)
  end

  def accreditation_type
    AccreditationDocumentGroup.pluck(:title).include?(params[:internal_document][:title])
  end
end
