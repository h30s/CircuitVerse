FactoryBot.define do
  factory :subgroup do
    sequence(:name) { |n| "Team #{n}" }
    association :group
    association :created_by, factory: :user
    max_members { 5 }
  end
end
