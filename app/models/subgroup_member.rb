class SubgroupMember < ApplicationRecord
  belongs_to :subgroup
  belongs_to :user

  enum :role, { member: 0, leader: 1 }

  validates :user_id, uniqueness: { scope: :subgroup_id, message: "is already in this subgroup" }
  validate  :user_belongs_to_parent_group
  validate  :subgroup_not_full, on: :create
  validate  :single_leader, if: :leader?

  private

  def user_belongs_to_parent_group
    return unless subgroup
    unless GroupMember.exists?(group_id: subgroup.group_id, user_id: user_id)
      errors.add(:user, "must be a member of the parent group")
    end
  end

  def subgroup_not_full
    return unless subgroup
    errors.add(:subgroup, "has reached its maximum capacity of #{subgroup.max_members}") if subgroup.full?
  end

  def single_leader
    return unless subgroup
    existing_leader = subgroup.subgroup_members.where(role: :leader).where.not(id: id)
    errors.add(:role, "cannot have multiple leaders in one subgroup") if existing_leader.exists?
  end
end
