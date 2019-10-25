require 'rails_helper'
require 'project_model_spec_setup_helpers.rb'

describe "filter by title" do
  include ProjectModelSpecSetupHelpers

  before do
    @project1 = FactoryBot.create(:project,
                                  title: 'bish bash bosh',
                                  mandate_id: promiscuous_query[:mandate_ids].first,
                                  subarea_ids: promiscuous_query[:subarea_ids][ 0..1 ],
                                  performance_indicator_ids: promiscuous_query[:performance_indicator_ids][ 0..1])

    @project2 = FactoryBot.create(:project,
                                  title: 'whassup dude',
                                  mandate_id: promiscuous_query[:mandate_ids].second,
                                  subarea_ids: promiscuous_query[:subarea_ids][ 0..1 ],
                                  performance_indicator_ids: promiscuous_query[:performance_indicator_ids][ 0..1])

  end

  it "should return all projects when title query is blank" do
    result = Project.filtered(promiscuous_query).to_a
    expect(result).to match_array [@project1, @project2]
  end

  it "should return projects matching title fragment" do
    query = promiscuous_query.merge({title: "bish"})
    result = Project.filtered(query).to_a
    expect(result).to eq [@project1]
  end
end

describe "filter undesignated subarea" do
  before do
    @project_area1 = ProjectSubarea.create(name: "foobar")
    @project_area2 = ProjectSubarea.create(name: "quackquack")
    @project1 = FactoryBot.create(:project, title: 'bish bash bosh', subarea_ids: [@project_area1.id])
    @project2 = FactoryBot.create(:project, title: 'whassup dude', subarea_ids: [])
  end

  it "should return the projects without areas" do
    result = Project.with_subareas([0])
    expect(result).to match_array [@project2]
  end
end

describe "filter by mandate" do
  include ProjectModelSpecSetupHelpers
  before do
    @mandate1 = Mandate.create(name: "foobar")
    @mandate2 = Mandate.create(name: "bizboz")
    @project1 = FactoryBot.create(:project,
                                  mandate_id: @mandate1.id,
                                  subarea_ids: promiscuous_query[:subarea_ids][ 0..1 ],
                                  performance_indicator_ids: promiscuous_query[:performance_indicator_ids][ 0..1])
    @project2 = FactoryBot.create(:project,
                                  mandate_id: @mandate2.id,
                                  subarea_ids: promiscuous_query[:subarea_ids][ 0..1 ],
                                  performance_indicator_ids: promiscuous_query[:performance_indicator_ids][ 0..1])
    @project3 = FactoryBot.create(:project,
                                  mandate_id: nil,
                                  subarea_ids: promiscuous_query[:subarea_ids][ 0..1 ],
                                  performance_indicator_ids: promiscuous_query[:performance_indicator_ids][ 0..1])
  end

  it "should return projects without mandate designation" do
    query = promiscuous_query.merge({mandate_ids: ["0"]})
    result = Project.filtered(query).to_a
    expect(result).to match_array [@project3]
  end

  it "should return projects with matching area designation" do
    query = promiscuous_query.merge({mandate_ids: [@mandate1.id]})
    result = Project.filtered(query).to_a
    expect(result).to eq [@project1]
  end

  it "should return no projects" do
    query = promiscuous_query.merge({mandate_ids: [""]})
    result = Project.filtered(query).to_a
    expect(result).to be_empty
  end
end

describe "filter by subarea_ids" do
  include ProjectModelSpecSetupHelpers

  before do
    @project_subarea1 = FactoryBot.create(:project_subarea, :human_rights)
    @project_subarea2 = FactoryBot.create(:project_subarea, :good_governance)
    @project1 = FactoryBot.create(:project,
                                  mandate_id: promiscuous_query[:mandate_ids][0],
                                  subarea_ids: [@project_subarea1.id],
                                  performance_indicator_ids: promiscuous_query[:performance_indicator_ids][ 0..1])
    @project2 = FactoryBot.create(:project,
                                  mandate_id: promiscuous_query[:mandate_ids][0],
                                  subarea_ids: [@project_subarea2.id],
                                  performance_indicator_ids: promiscuous_query[:performance_indicator_ids][ 0..1])
    @project3 = FactoryBot.create(:project,
                                  mandate_id: promiscuous_query[:mandate_ids][0],
                                  subarea_ids: [""],
                                  performance_indicator_ids: promiscuous_query[:performance_indicator_ids][ 0..1])
  end

  context "when no filter is in effect" do
    let(:result){ Project.filtered(promiscuous_query).to_a }

    it "should return all projects" do
      expect(result).to match_array [@project1, @project2, @project3]
    end
  end

  context "when specific subareas are requested" do
    let(:query){ promiscuous_query.merge({subarea_ids: [@project_subarea1.id]}) }

    it "should return all projects" do
      result = Project.filtered(query).to_a
      expect(result).to match_array [@project1]
    end
  end

end

describe "filter by performance indicator ids" do
  include ProjectModelSpecSetupHelpers

  before do
    FactoryBot.create(:strategic_plan, :populated)
    @pi1, @pi2 = PerformanceIndicator.limit(2)
    @project1 = FactoryBot.create(:project, performance_indicator_ids: [@pi1.id])
    @project2 = FactoryBot.create(:project, performance_indicator_ids: [@pi2.id])
    @project3 = FactoryBot.create(:project, performance_indicator_ids: [])
  end

  context "when no filter is invoked" do
    let(:result){ Project.filtered(query).to_a }
    let(:query){ {subarea_ids: ["0"], mandate_ids: [""], performance_indicator_ids: [""]} }

    it "result should include no projects" do
      expect(result).to match_array []
    end
  end

  context "when performance indicator filter is invoked" do
    let(:result){ Project.filtered(query).to_a }
    let(:query){ promiscuous_query.merge({performance_indicator_ids: [@pi1.id]}) }

    it "result should include all projects" do
      expect(result).to match_array [@project1]
    end
  end

  context "when all performance indicators are requested" do
    let(:query){ promiscuous_query.merge({performance_indicator_ids: [@pi1.id, @pi2.id]}) }
    let(:result){ Project.filtered(query).to_a }

    it "result should include all projects" do
      expect(result).to match_array [@project1, @project2]
    end
  end
end
