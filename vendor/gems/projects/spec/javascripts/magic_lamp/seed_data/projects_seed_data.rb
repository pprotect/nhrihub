class ProjectsSeedData
  def self.initialize(model)
    self.send("init_#{model.to_s}")
  end

  def self.init_projects
    FactoryBot.create(:project)
    project = Project.first
    project.areas = [FactoryBot.create(:mandate, :key => 'human_rights')]
    project.save
    project
  end

  def self.init_project_types
    []
  end

  def self.init_agencies
    []
  end

  def self.init_conventions
    []
  end
end
