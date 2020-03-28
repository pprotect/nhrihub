class AgencyReporter::AgencyListsController < ApplicationController
  def show
    respond_to do |format|
      format.docx do
        send_file AgenciesReport.new(Agency.hierarchy).docfile
      end
    end
  end
end
