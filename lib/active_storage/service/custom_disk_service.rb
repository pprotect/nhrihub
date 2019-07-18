require 'active_storage/service/disk_service'

module ActiveStorage
  class Service::CustomDiskService < Service::DiskService

  private
    def folder_for(key)
      ''
    end
  end
end

