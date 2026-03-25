FactoryBot.define do
  factory :subgroup_member do
    association :subgroup
    association :user
    role { :member }
  end
end
