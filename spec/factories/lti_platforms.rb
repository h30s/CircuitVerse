FactoryBot.define do
  factory :lti_platform do
    sequence(:issuer) { |n| "https://canvas#{n}.test.instructure.com" }
    sequence(:client_id) { |n| "1000000000000#{n}" }
    auth_endpoint { "https://canvas.test/api/lti/authorize_redirect" }
    token_endpoint { "https://canvas.test/login/oauth2/token" }
    public_key_set_url { "https://canvas.test/api/lti/security/jwks" }
  end
end
