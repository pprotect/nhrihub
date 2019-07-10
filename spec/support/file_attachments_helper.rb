module FactoryBot
  module FileAttachmentsHelper
    extend self
    extend ActionDispatch::TestProcess

    MimeTypes = { pdf: 'application/pdf',
                  png: 'image/png' }

    def png; upload('first_upload_image_file.png', MimeTypes[:png] ) end

    def pdf; upload('first_upload_file.pdf', MimeTypes[:pdf] ) end

    def pdf1; upload('first_upload_file1.pdf', MimeTypes[:pdf] ) end

    def pdf2; upload('first_upload_file2.pdf', MimeTypes[:pdf] ) end

    def big_pdf; upload('big_upload_file.pdf', MimeTypes[:pdf] ) end

    #def jpg_name; 'test-image.jpg' end
    #def jpg; upload(jpg_name, 'image/jpg') end

    #def tiff_name; 'test-image.tiff' end
    #def tiff; upload(tiff_name, 'image/tiff') end

    private

    def upload(name, type)
      file_path = Rails.root.join('spec', 'support', 'uploadable_files', name)
      fixture_file_upload(file_path, type)
    end
  end
end
