require "rails_helper"

RSpec.describe AssignmentTestCase, type: :model do
  let(:mentor)     { create(:user) }
  let(:group)      { create(:group, primary_mentor: mentor) }
  let(:assignment) { create(:assignment, group: group) }

  describe "validations" do
    it "is valid with correct attributes" do
      tc = build(:assignment_test_case, assignment: assignment,
                 name: "AND gate test",
                 inputs: { "A" => 1, "B" => 1 },
                 expected_outputs: { "Y" => 1 })
      expect(tc).to be_valid
    end

    it "requires a name" do
      tc = build(:assignment_test_case, assignment: assignment, name: nil)
      expect(tc).not_to be_valid
    end

    it "requires inputs to be a hash of integers" do
      tc = build(:assignment_test_case, assignment: assignment,
                 inputs: { "A" => "high" })
      expect(tc).not_to be_valid
      expect(tc.errors[:inputs].first).to include("integer values")
    end

    it "requires expected_outputs to be a hash of integers" do
      tc = build(:assignment_test_case, assignment: assignment,
                 expected_outputs: "wrong")
      expect(tc).not_to be_valid
    end

    it "requires points > 0" do
      tc = build(:assignment_test_case, assignment: assignment, points: 0)
      expect(tc).not_to be_valid
    end
  end

  describe "ordering" do
    it "orders by position" do
      tc2 = create(:assignment_test_case, assignment: assignment, position: 2, name: "B")
      tc1 = create(:assignment_test_case, assignment: assignment, position: 1, name: "A")

      expect(assignment.assignment_test_cases.pluck(:name)).to eq(["A", "B"])
    end
  end
end
