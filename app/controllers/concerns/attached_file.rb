module AttachedFile
  def send_blob(file_owner)
    send_opts = { :filename => file_owner.send(:original_filename),
                  :type => file_owner.send(:original_type),
                  :disposition => :attachment,
                  :x_sendfile => true }
    send_data file_owner.file.download, send_opts
  end
end
