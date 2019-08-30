FactoryBot.define do
  factory :complaint_basis do
    trait :siu do
      name { Siu::ComplaintBasis::DefaultNames.sample }
      type { "Siu::ComplaintBasis" }
    end

    trait :gg do
      name { GoodGovernance::ComplaintBasis::DefaultNames.sample }
      type { "GoodGovernance::ComplaintBasis" }
    end

    trait :hr do
      name { CONVENTIONS.keys.sample }
      full_name { CONVENTIONS[name] }
    end

    trait :cs do
      name { StrategicPlans::ComplaintBasis::DefaultNames.sample }
      type { "Nhri::ComplaintBasis" }
    end

    factory :siu_complaint_basis, :class => Siu::ComplaintBasis, :traits => [:siu]
    factory :good_governance_complaint_basis, :class => GoodGovernance::ComplaintBasis, :traits => [:gg]
    factory :hr_complaint_basis, :class => Nhri::ComplaintBasis, :traits => [:hr]
    factory :cs_complaint_basis, :class => StrategicPlans::ComplaintBasis, :traits => [:cs]
  end
end
