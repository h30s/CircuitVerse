require "rails_helper"

RSpec.describe SubgroupMember, type: :model do
  let(:mentor)   { create(:user) }
  let(:group)    { create(:group, primary_mentor: mentor) }
  let(:member_1) { create(:user) }
  let(:member_2) { create(:user) }
  let(:subgroup) { create(:subgroup, group: group, created_by: mentor, max_members: 2) }

  before do
    create(:group_member, group: group, user: member_1)
    create(:group_member, group: group, user: member_2)
  end

  describe "validations" do
    it "is valid with a group member" do
      sm = build(:subgroup_member, subgroup: subgroup, user: member_1)
      expect(sm).to be_valid
    end

    it "rejects users not in parent group" do
      outsider = create(:user)
      sm = build(:subgroup_member, subgroup: subgroup, user: outsider)

      expect(sm).not_to be_valid
      expect(sm.errors[:user]).to include("must be a member of the parent group")
    end

    it "prevents duplicate membership" do
      create(:subgroup_member, subgroup: subgroup, user: member_1)
      duplicate = build(:subgroup_member, subgroup: subgroup, user: member_1)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to include("is already in this subgroup")
    end

    it "prevents exceeding max_members" do
      create(:subgroup_member, subgroup: subgroup, user: member_1)
      create(:subgroup_member, subgroup: subgroup, user: member_2)

      member_3 = create(:user)
      create(:group_member, group: group, user: member_3)

      sm = build(:subgroup_member, subgroup: subgroup, user: member_3)
      expect(sm).not_to be_valid
      expect(sm.errors[:subgroup].first).to include("maximum capacity")
    end

    it "prevents multiple leaders in one subgroup" do
      create(:subgroup_member, subgroup: subgroup, user: member_1, role: :leader)
      second_leader = build(:subgroup_member, subgroup: subgroup, user: member_2, role: :leader)

      expect(second_leader).not_to be_valid
      expect(second_leader.errors[:role]).to include("cannot have multiple leaders in one subgroup")
    end
  end

  describe "role enum" do
    it "defaults to member" do
      sm = create(:subgroup_member, subgroup: subgroup, user: member_1)
      expect(sm.member?).to be true
    end

    it "can be set to leader" do
      sm = create(:subgroup_member, subgroup: subgroup, user: member_1, role: :leader)
      expect(sm.leader?).to be true
    end
  end
end
