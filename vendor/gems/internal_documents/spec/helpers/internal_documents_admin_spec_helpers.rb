require 'rspec/core/shared_context'

module InternalDocumentAdminSpecHelpers
  extend RSpec::Core::SharedContext
  def model
    InternalDocument
  end

  def admin_page
    internal_document_admin_path('en')
  end

  def filesize_context
    page.find('#internal_document_filesize')
  end

  def filetypes_context
    page.find(filetypes_selector)
  end

  def filetypes_selector
    '#internal_document_filetypes'
  end

  def remove_add_delete_fileconfig_permissions
    allow_any_instance_of(AuthorizedSystem).to receive(:permitted?).with('internal_documents/filetypes','create').and_return(false)
    allow_any_instance_of(AuthorizedSystem).to receive(:permitted?).with('internal_documents/filetypes','destroy').and_return(false)
    allow_any_instance_of(AuthorizedSystem).to receive(:permitted?).with('internal_documents/filetypes','update').and_return(false)
    allow_any_instance_of(AuthorizedSystem).to receive(:permitted?).with('internal_documents/filesizes','create').and_return(false)
    allow_any_instance_of(AuthorizedSystem).to receive(:permitted?).with('internal_documents/filesizes','destroy').and_return(false)
    allow_any_instance_of(AuthorizedSystem).to receive(:permitted?).with('internal_documents/filesizes','update').and_return(false)
  end
end
