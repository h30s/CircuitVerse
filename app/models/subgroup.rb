class Subgroup < ApplicationRecord
  belongs_to :group
  belongs_to :created_by, class_name: "User"
  has_many   :subgroup_members, dependent: :destroy
  has_many   :users, through: :subgroup_members

  validates :name, presence: true,
                   length: { minimum: 1, maximum: 100 }
  validates :max_members, numericality: { greater_than: 0, less_than_or_equal_to: 20 }
  validate  :members_within_parent_group

  scope :for_group, ->(group_id) { where(group_id: group_id) }

  def leader
    subgroup_members.find_by(role: :leader)&.user
  end

  def full?
    subgroup_members.count >= max_members
  end

  private

  def members_within_parent_group
    return if users.empty?
    parent_user_ids = GroupMember.where(group_id: group_id).pluck(:user_id)
    orphaned = user_ids - parent_user_ids
    errors.add(:users, "must all be members of the parent group (invalid: #{orphaned.join(', ')})") if orphaned.any?
  end
end
