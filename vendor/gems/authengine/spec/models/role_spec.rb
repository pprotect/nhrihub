require 'rails_helper'

describe "ancestors method" do
  before(:each) do
    @big_boss = Role.create(:name => "big_boss", :parent_id => nil)
    @boss = Role.create(:name => "boss", :parent_id => @big_boss.id)
    @minion = Role.create(:name => "minion", :parent_id => @boss.id)
  end

  it "minions ancestors should include boss and big boss" do
    expect(@minion.ancestors).to include(@boss)
    expect(@minion.ancestors).to include(@big_boss)
    expect(@minion.ancestors.size).to eq(2)
    expect(@boss.ancestors).to include(@big_boss)
    expect(@boss.ancestors.size).to eq(1)
    expect(@big_boss.ancestors).to be_empty
  end

end

describe "equal_or_lower_than class method" do
  before(:each) do
    @big_boss = Role.create(:name => "big_boss", :parent_id => nil)
    @boss = Role.create(:name => "boss", :parent_id => @big_boss.id)
    @minion = Role.create(:name => "minion", :parent_id => @boss.id)
  end

  it "should return minion and boss when parameter is 'boss'" do
    expect(Role.equal_or_lower_than(@boss)).to include(@minion)
    expect(Role.equal_or_lower_than(@boss)).to include(@boss)
  end

  it "should return minion and boss and big_boss when parameter is an array ['boss','big_boss']" do
    expect(Role.equal_or_lower_than([@boss, @big_boss])).to include(@minion)
    expect(Role.equal_or_lower_than([@boss, @big_boss])).to include(@boss)
    expect(Role.equal_or_lower_than([@boss, @big_boss])).to include(@big_boss)
  end
end

describe "role assignment logging" do
  before do
    @admin = FactoryBot.create(:user)
  end

  describe "role creation" do
    it "should create a role_assignment event" do
      expect{ FactoryBot.create(:role, name: 'bossman', administrator: @admin) }.to change{ RoleAssignment.count }.by(1)
      ra = RoleAssignment.last
      expect(ra.assigner_id).to eq 1
      expect(ra.assignee_id).to be_blank
      expect(ra.action).to eq "create"
      expect(ra.role_name).to eq "bossman"
    end
  end

  describe "role deletion" do
    before do
      @role = FactoryBot.create(:role, name: 'bossman', administrator: @admin)
    end

    it "should create a role_assignment event" do
      expect{@role.destroy}.to change{ RoleAssignment.count }.by(1)
      ra = RoleAssignment.last
      expect(ra.assigner_id).to eq @admin.id
      expect(ra.assignee_id).to be_blank
      expect(ra.action).to eq "delete"
      expect(ra.role_name).to eq "bossman"
    end
  end

  describe "role assignment" do
    before do
      administrator = FactoryBot.create(:user)
      @role = FactoryBot.create(:role, name: 'bossman', administrator: administrator)
      @user = FactoryBot.create(:user)
    end

    it "should create a role_assignment event" do
      expect{UserRole.create(user_id: @user.id, role_id: @role.id, assigner: @admin)}.to change{RoleAssignment.count}.by(1)
      ra = RoleAssignment.last
      expect(ra.assigner_id).to eq @admin.id
      expect(ra.assignee_id).to eq @user.id
      expect(ra.action).to eq "assign"
      expect(ra.role_name).to eq "bossman"
    end
  end

  describe "role deassigment" do
    before do
      administrator = FactoryBot.create(:user)
      @role = FactoryBot.create(:role, name: 'bossman', administrator: administrator)
      @user = FactoryBot.create(:user)
      @user_role = UserRole.create(user_id: @user.id, role_id: @role.id, assigner: @admin)
    end

    it "should create a role_assignment event" do
      expect{@user_role.destroy}.to change{RoleAssignment.count}.by(1)
      ra = RoleAssignment.last
      expect(ra.assigner_id).to eq @admin.id
      expect(ra.assignee_id).to eq @user.id
      expect(ra.action).to eq "deassign"
      expect(ra.role_name).to eq "bossman"
    end
  end
end
