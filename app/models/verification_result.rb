class VerificationResult < ApplicationRecord
  belongs_to :project
  belongs_to :assignment_test_case

  validates :status, inclusion: { in: %w[pending passed failed unstable] }

  scope :passed,   -> { where(status: "passed") }
  scope :failed,   -> { where(status: "failed") }
  scope :unstable, -> { where(status: "unstable") }

  def self.score_percentage
    return 0.0 if count.zero?
    passed_points = passed.joins(:assignment_test_case).sum("assignment_test_cases.points")
    total_points  = joins(:assignment_test_case).sum("assignment_test_cases.points")
    (passed_points.to_f / total_points * 100).round(1)
  end
end
