class AssignmentTestCase < ApplicationRecord
  belongs_to :assignment
  has_many   :verification_results, dependent: :destroy

  validates :name, presence: true, length: { maximum: 255 }
  validates :inputs, :expected_outputs, presence: true
  validates :points, numericality: { greater_than: 0 }
  validate  :valid_io_format

  default_scope { order(position: :asc) }

  def total_possible_points
    assignment.assignment_test_cases.sum(:points)
  end

  private

  def valid_io_format
    unless inputs.is_a?(Hash) && inputs.values.all? { |v| v.is_a?(Integer) }
      errors.add(:inputs, "must be a hash of probe names to integer values")
    end
    unless expected_outputs.is_a?(Hash) && expected_outputs.values.all? { |v| v.is_a?(Integer) }
      errors.add(:expected_outputs, "must be a hash of probe names to integer values")
    end
  end
end
