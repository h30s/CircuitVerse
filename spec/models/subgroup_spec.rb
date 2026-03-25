require "rails_helper"

RSpec.describe Subgroup, type: :model do
  let(:mentor) { create(:user) }
  let(:group)  { create(:group, primary_mentor: mentor) }
  let(:member) { create(:user) }

  before do
    create(:group_member, group: group, user: member)
  end

  describe "validations" do
    it "is valid with valid attributes" do
      subgroup = build(:subgroup, group: group, created_by: mentor)
      expect(subgroup).to be_valid
    end

    it "requires a name" do
      subgroup = build(:subgroup, group: group, created_by: mentor, name: nil)
      expect(subgroup).not_to be_valid
      expect(subgroup.errors[:name]).to include("can't be blank")
    end

    it "enforces name length limit" do
      subgroup = build(:subgroup, group: group, created_by: mentor, name: "a" * 101)
      expect(subgroup).not_to be_valid
    end

    it "requires max_members > 0" do
      subgroup = build(:subgroup, group: group, created_by: mentor, max_members: 0)
      expect(subgroup).not_to be_valid
    end

    it "requires max_members <= 20" do
      subgroup = build(:subgroup, group: group, created_by: mentor, max_members: 21)
      expect(subgroup).not_to be_valid
    end

    it "validates members belong to parent group" do
      outsider = create(:user)  # NOT a member of group
      subgroup = create(:subgroup, group: group, created_by: mentor)
      
      expect {
        subgroup.users << outsider
      }.to raise_error(ActiveRecord::RecordInvalid, /User must be a member of the parent group/)
    end
  end

  describe "associations" do
    it "belongs to a group" do
      subgroup = create(:subgroup, group: group, created_by: mentor)
      expect(subgroup.group).to eq(group)
    end

    it "destroys subgroup_members when destroyed" do
      subgroup = create(:subgroup, group: group, created_by: mentor)
      create(:subgroup_member, subgroup: subgroup, user: member)

      expect { subgroup.destroy }.to change(SubgroupMember, :count).by(-1)
    end
  end

  describe "#leader" do
    it "returns the leader user" do
      subgroup = create(:subgroup, group: group, created_by: mentor)
      create(:subgroup_member, subgroup: subgroup, user: member, role: :leader)

      expect(subgroup.leader).to eq(member)
    end

    it "returns nil when no leader is assigned" do
      subgroup = create(:subgroup, group: group, created_by: mentor)
      expect(subgroup.leader).to be_nil
    end
  end

  describe "#full?" do
    it "returns true when at max capacity" do
      subgroup = create(:subgroup, group: group, created_by: mentor, max_members: 1)
      create(:subgroup_member, subgroup: subgroup, user: member)

      expect(subgroup.full?).to be true
    end

    it "returns false when under capacity" do
      subgroup = create(:subgroup, group: group, created_by: mentor, max_members: 5)
      expect(subgroup.full?).to be false
    end
  end
end
