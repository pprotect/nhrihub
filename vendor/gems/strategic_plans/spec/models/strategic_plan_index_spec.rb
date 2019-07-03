require 'rails_helper'

describe "" do
  before do
    @spr = StrategicPriority.create(:priority_level => '1', :description => "foo")
    @p = PlannedResult.create(:description => "foo", :strategic_priority => @spr)
    @o1 = Outcome.create(:planned_result => @p, :description => "bar")
    @o2 = Outcome.create(:planned_result => @p, :description => "bar")
  end

  it "should have default scope ordered by index" do
    expect(Outcome.all.to_a).to eq [@o1,@o2]
  end

  it "should create index values" do
    expect(@p.index).to eq "1.1"
    expect(@o1.index).to eq "1.1.1"
    expect(@o2.index).to eq "1.1.2"
  end

  it "o2 should be > o1" do
    expect(@o2>=@o1).to be true
  end

  it "should identify siblings" do
    expect(@o2.siblings.to_a).to match_array [@o1,@o2]
    expect(@o1.siblings.to_a).to match_array [@o1,@o2]
  end

  it "should identify lower priority siblings" do
    expect(@o1.lower_priority_siblings.to_a).to match_array [@o2, @o1]
    expect(@o2.lower_priority_siblings.to_a).to match_array [@o2]
  end

  it "should have a comparison operator" do
    expect(@o1<=>@o2).to eq -1
    expect(@o2<=>@o1).to eq 1
    expect(@o2<=>@o2).to eq 0
  end

  it "should decrement an index" do
    @o2.decrement_index
    expect(@o2.index).to eq "1.1.1"
  end

  it "should increment index root" do
    @o2.increment_index_root
    #started at "1.1.2"
    expect(@o2.index).to eq "2.1.2"
  end

  it "should decrement index prefix" do
    @o2.decrement_index_prefix("0.0")
    expect(@o2.index).to eq "0.0.2"
  end

  it "should show indexed description" do
    expect(@o2.indexed_description).to eq "1.1.2 bar"
  end

  it "should understand it's parent's index" do
    expect(@o2.send(:parent_index)).to eq "1.1"
  end

  it "should know the last index assigned" do
    expect(@o1.send(:previous_instance)).to eq @o2
  end

  it "should determine the next index to assign" do
    expect(@o2.send(:incremented_index)).to eq "1.1.3"
  end

end

describe "higher-level actions" do
  before do
    @spr = StrategicPriority.create(:priority_level => '1', :description => "foo")
    @p1 = PlannedResult.create(:description => "foo", :strategic_priority => @spr)
    @o11 = Outcome.create(:planned_result => @p1, :description => "bar")
    @o12 = Outcome.create(:planned_result => @p1, :description => "bar")
    @p2 = PlannedResult.create(:description => "foo", :strategic_priority => @spr)
    @o21 = Outcome.create(:planned_result => @p2, :description => "bar")
    @o22 = Outcome.create(:planned_result => @p2, :description => "bar")
  end

  describe "delete a high priority outcome" do
    before do
      @p1.destroy
      @o23 = Outcome.create(:planned_result => @p2, :description => "bar")
    end

    it "should adjust lower priority outcomes" do
      # lower priority outcomes and activities have their indexes adjusted
      expect(@p2.reload.index).to eq "1.1"
      # adding activities to the adjusted outcome, should have appropriate indexes
      expect(@o23.index).to eq "1.1.3"
      # the next planned result should have the appropriate index
      p3 = PlannedResult.create(:description => "foo", :strategic_priority => @spr)
      expect(p3.index).to eq '1.2'
    end
  end
end
