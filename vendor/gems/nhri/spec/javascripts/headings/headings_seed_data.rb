class HeadingsSeedData
  def self.initialize(fixture)
    send(:"#{fixture}_init")
  end

  def self.headings_init
    FactoryBot.create(:heading, :with_three_human_rights_attributes)
  end
end
