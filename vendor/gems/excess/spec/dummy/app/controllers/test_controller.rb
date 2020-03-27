class TestController < ApplicationController
  def index
    respond_to do |format|
      format.html
      format.xlsx { render :xlsx => "test_doc" }
    end
  end
end
