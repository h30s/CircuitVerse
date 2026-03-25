FactoryBot.define do
  factory :assignment_test_case do
    sequence(:name) { |n| "Test Case #{n}" }
    inputs { { "A" => 1, "B" => 0 } }
    expected_outputs { { "Y" => 1 } }
    points { 10 }
    association :assignment
  end
end
