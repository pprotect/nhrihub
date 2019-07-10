class ComplaintDocumentsController < ApplicationController
  include AttachedFile

  def destroy
    @complaint_document = ComplaintDocument.find(params[:id])
    @complaint_document.destroy
    head :ok
  end

  def show
    send_blob(ComplaintDocument.find(params[:id]))
  end
end
