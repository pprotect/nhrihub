class InternalDocumentSeed
  def self.rand_title
    l = rand(4)+4
    Faker::Lorem.words(l).join(' ')
  end

  def self.rand_filename
    l = rand(3)+3
    Faker::Lorem.words(l).join('_').downcase + ".pdf"
  end

  def self.rev
    ((rand(49)+50).to_f/10).to_s
  end

  def self.populate_test_data
    3.times do
      doc = FactoryBot.create(:internal_document, :revision => rev, :title => rand_title, :original_filename => rand_filename)
      2.times do
        doc = FactoryBot.create(:internal_document, :document_group_id => doc.document_group_id)
      end
    end
    FactoryBot.create(:accreditation_required_document, :revision => rev, :title => "Statement of Compliance", :original_filename => rand_filename)
  end
end
