require "rails_helper"

RSpec.describe LtiPlatform, type: :model do
  describe "validations" do
    it "is valid with required attributes" do
      platform = build(:lti_platform)
      expect(platform).to be_valid
    end

    it "requires issuer" do
      platform = build(:lti_platform, issuer: nil)
      expect(platform).not_to be_valid
    end

    it "enforces unique issuer + client_id" do
      create(:lti_platform, issuer: "https://canvas.test", client_id: "abc")
      duplicate = build(:lti_platform, issuer: "https://canvas.test", client_id: "abc")
      expect(duplicate).not_to be_valid
    end
  end

  describe "#generate_keypair!" do
    it "generates RSA key pair" do
      platform = create(:lti_platform)
      platform.generate_keypair!

      expect(platform.tool_private_key).to include("BEGIN RSA PRIVATE KEY")
      expect(platform.tool_public_key).to include("BEGIN PUBLIC KEY")
    end
  end

  describe "#jwk" do
    it "returns a valid JWK" do
      platform = create(:lti_platform)
      platform.generate_keypair!

      jwk = platform.jwk
      exported = jwk.export
      expect(exported[:kty]).to eq("RSA")
      expect(exported[:alg]).to eq("RS256")
    end
  end
end
