FactoryBot.define do
  factory :verification_result do
    association :project
    association :assignment_test_case
    status { "pending" }
  end
end
