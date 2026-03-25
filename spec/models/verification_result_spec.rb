require "rails_helper"

RSpec.describe VerificationResult, type: :model do
  let(:mentor)     { create(:user) }
  let(:group)      { create(:group, primary_mentor: mentor) }
  let(:assignment) { create(:assignment, group: group) }
  let(:project)    { create(:project, assignment: assignment) }
  let(:test_case)  { create(:assignment_test_case, assignment: assignment, points: 10) }

  it "records a passed result" do
    vr = create(:verification_result,
                project: project,
                assignment_test_case: test_case,
                status: "passed",
                passed: true,
                actual_outputs: { "Y" => 1 })

    expect(vr.status).to eq("passed")
    expect(VerificationResult.passed.count).to eq(1)
  end

  it "records a failed result" do
    vr = create(:verification_result,
                project: project,
                assignment_test_case: test_case,
                status: "failed",
                passed: false,
                actual_outputs: { "Y" => 0 })

    expect(VerificationResult.failed.count).to eq(1)
  end

  it "prevents duplicate results per project+test_case" do
    create(:verification_result, project: project, assignment_test_case: test_case)

    expect {
      create(:verification_result, project: project, assignment_test_case: test_case)
    }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  describe ".score_percentage" do
    let(:tc1) { create(:assignment_test_case, assignment: assignment, points: 10, name: "A") }
    let(:tc2) { create(:assignment_test_case, assignment: assignment, points: 10, name: "B") }

    it "calculates correct percentage" do
      create(:verification_result, project: project, assignment_test_case: tc1, status: "passed")
      create(:verification_result, project: project, assignment_test_case: tc2, status: "failed")

      results = project.verification_results
      expect(results.score_percentage).to eq(50.0)
    end
  end
end
