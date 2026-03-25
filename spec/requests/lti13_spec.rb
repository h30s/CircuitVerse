require "rails_helper"

RSpec.describe "LTI 1.3 Endpoints", type: :request do
  let!(:platform) do
    create(:lti_platform,
           issuer: "https://canvas.test.instructure.com",
           client_id: "10000000000001",
           auth_endpoint: "https://canvas.test/api/lti/authorize_redirect",
           public_key_set_url: "https://canvas.test/api/lti/security/jwks")
  end

  before do
    Flipper.enable(:lti_v13_integration)
  end

  describe "POST /lti13/login" do
    it "redirects to Canvas OIDC auth endpoint" do
      post lti13_login_path, params: {
        iss: platform.issuer,
        client_id: platform.client_id,
        login_hint: "user123",
        lti_message_hint: "hint456"
      }

      expect(response).to have_http_status(:redirect)
      expect(response.location).to start_with(platform.auth_endpoint)
      expect(response.location).to include("response_type=id_token")
      expect(response.location).to include("scope=openid")
    end

    it "returns 404 for unknown platform" do
    post lti13_login_path, params: {
      iss: "https://unknown.example.com",
      client_id: "unknown"
    }
    expect(response).to have_http_status(:not_found)
  end
  end

  describe "GET /lti13/jwks" do
    it "returns the tool's public JWK set" do
      platform.generate_keypair!

      get lti13_jwks_path
      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)
      expect(body["keys"]).to be_an(Array)
      expect(body["keys"].first["kty"]).to eq("RSA")
    end
  end

  context "when LTI 1.3 is disabled" do
    before { Flipper.disable(:lti_v13_integration) }

    it "returns 404 for login" do
      post lti13_login_path, params: { iss: platform.issuer, client_id: platform.client_id }
      expect(response).to have_http_status(:not_found)
    end
  end
end
