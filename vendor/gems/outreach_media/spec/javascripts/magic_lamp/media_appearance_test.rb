class MediaAppearanceTest
  def self.populate_test_data
    ma = FactoryGirl.build(:media_appearance,
                            :hr_violation_subarea,
                            :crc_subarea,
                            :title => "Fantasy land",
                            # this time is stored as its UTC equivalent 12/31/14
                            # so the date method returns the intended value, 1/1/15
                            :created_at => DateTime.new(2015,1,1,0,0,0,'-8'),
                            :violation_coefficient => 10,
                            :affected_people_count => 555)
    ma.positivity_rating = FactoryGirl.create(:positivity_rating, :rank => 5)
    ma.violation_severity = FactoryGirl.create(:violation_severity, :rank => 5)
    ma.save

    ma = FactoryGirl.build(:media_appearance,
                            :hr_violation_subarea,
                            :crc_subarea,
                            :title => "May the force be with you",
                            :created_at => DateTime.new(2014,1,1,0,0,0,'-8'),
                            :violation_coefficient => 0.7,
                            :affected_people_count => 22)
    ma.positivity_rating = FactoryGirl.create(:positivity_rating, :rank => 2)
    ma.violation_severity = FactoryGirl.create(:violation_severity, :rank => 2)
    ma.save

    6.times do |i|
      ma = FactoryGirl.build(:media_appearance,
                              :no_f_in_title,
                              :si_area,
                              :created_at => DateTime.new(2014,1,1,0,0,0,'-8'),
                              :violation_coefficient => 10,
                              :affected_people_count => 5000)
      ma.positivity_rating = FactoryGirl.create(:positivity_rating, :rank => 1)
      ma.violation_severity = FactoryGirl.create(:violation_severity, :rank => 1)
      ma.save
    end
  end
end
