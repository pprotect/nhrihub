class ComplaintsSeedData
  def self.initialize(model)
    self.send("init_#{model.to_s}")
  end

  def self.init_statuses
    ["Active", "Complete", "No further action", "Presumed Resolved", "Suspended", "Under Evaluation"].each do |status|
      FactoryBot.create(:complaint_status, :name => status)
    end
  end

  def self.init_special_investigations_unit_complaint_bases
    #Siu::ComplaintBasis.all
    Siu::ComplaintBasis::DefaultNames.each do |name|
      FactoryBot.create(:siu_complaint_basis, :name => name)
    end
  end

  def self.init_human_rights_complaint_bases
    CONVENTIONS.keys.each do |name|
      FactoryBot.create(:convention, :name => name)
    end
  end

  def self.init_good_governance_complaint_bases
    GoodGovernance::ComplaintBasis::DefaultNames.each do |name|
      FactoryBot.create(:good_governance_complaint_basis, :name => name)
    end
  end

  def self.init_staff_users
    FactoryBot.create(:user, :staff)
  end

  def self.init_complaints_data
    GoodGovernance::ComplaintBasis::DefaultNames.sample(4).each do |name|
      FactoryBot.create(:complaint_basis, :gg, :name => name)
    end

    GoodGovernance::ComplaintBasis::DefaultNames.sample(2).each do |name|
      FactoryBot.create(:complaint_basis, :siu, :name => name)
    end

    Nhri::ComplaintBasis::DefaultNames.sample(2).each do |name|
      FactoryBot.create(:convention)
    end

    AGENCIES.keys.sample(2).each do |name|
      Agency.create(:name => name)
    end

    active_complaint_status = FactoryBot.create(:complaint_status, :id => 1, :name => "Active")
    completed_complaint_status = FactoryBot.create(:complaint_status, :id => 2, :name => "Completed")

    FactoryBot.create(:complaint,
                       :chiefly_title => "Arjuna",
                       :firstName => "Camilla",
                       :lastName  => "Lebsack",
                       :village => "Katherineborough",
                       :phone => "802-850-1615 x1496",
                       :case_reference => "c16/31",
                       :date_received => DateTime.new(2016,1,1),
                       :good_governance_complaint_basis_ids => [1,2],
                       :human_rights_complaint_basis_ids => [1,2],
                       :special_investigations_unit_complaint_basis_ids => [5,6],
                       :agency_ids => [1],
                       :assignees => [FactoryBot.create(:user, :with_password, :staff, :firstName => "Peyton", :lastName => "Krajcik")],
                       :status_changes => [FactoryBot.create(:status_change,
                                                              :complaint_status_id => active_complaint_status.id)])

    FactoryBot.create(:complaint,
                       :chiefly_title => "Arjuna",
                       :firstName => "Bo",
                       :lastName  => "McCullough",
                       :village => "Conroytown",
                       :phone => "(567) 894-1478 x4153",
                       :case_reference => "c16/32",
                       :date_received => DateTime.new(2016,1,1),
                       :good_governance_complaint_basis_ids => [3,4],
                       :human_rights_complaint_basis_ids => [1,2],
                       :special_investigations_unit_complaint_basis_ids => [5,6],
                       :agency_ids => [2],
                       :assignees => [FactoryBot.create(:user, :with_password, :staff, :firstName => "Angelina", :lastName => "Ward")],
                       :status_changes => [FactoryBot.create(:status_change,
                                                              :complaint_status_id => active_complaint_status.id)])

    FactoryBot.create(:complaint,
                       :chiefly_title => "Arjuna",
                       :firstName => "Ned",
                       :lastName  => "Kessler",
                       :village => "Port Janiya",
                       :phone => "1-862-553-8009 x835",
                       :case_reference => "c16/33",
                       :date_received => DateTime.new(2016,1,1),
                       :good_governance_complaint_basis_ids => [3,4],
                       :human_rights_complaint_basis_ids => [1,2],
                       :special_investigations_unit_complaint_basis_ids => [5,6],
                       :agency_ids => [2],
                       :assignees => [FactoryBot.create(:user, :with_password, :staff, :firstName => "Hosea", :lastName => "O'Connor")],
                       :status_changes => [FactoryBot.create(:status_change,
                                                              :complaint_status_id => completed_complaint_status.id)])

    FactoryBot.create(:complaint,
                       :chiefly_title => "Arjuna",
                       :firstName => "Marissa",
                       :lastName  => "Yost",
                       :village => "Parkerfurt",
                       :phone => "150-042-4712" ,
                       :case_reference => "c16/34",
                       :date_received => DateTime.new(2016,9,17),
                       :good_governance_complaint_basis_ids => [3,4],
                       :human_rights_complaint_basis_ids => [1,2],
                       :special_investigations_unit_complaint_basis_ids => [5,6],
                       :agency_ids => [2],
                       :assignees => [FactoryBot.create(:user, :with_password, :staff, :firstName => "Delbert", :lastName => "Brown")],
                       :status_changes => [FactoryBot.create(:status_change,
                                                              :complaint_status_id => completed_complaint_status.id)])

  end
end
