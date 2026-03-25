class LtiPlatform < ApplicationRecord
  belongs_to :group, optional: true

  validates :issuer, presence: true
  validates :client_id, presence: true
  validates :issuer, uniqueness: { scope: :client_id }
  validates :auth_endpoint, presence: true
  validates :public_key_set_url, presence: true

  # encrypts :tool_private_key  # (Removed for MVP to bypass missing DB encryption credentials)

  def generate_keypair!
    key = OpenSSL::PKey::RSA.new(2048)
    self.tool_private_key = key.to_pem
    self.tool_public_key  = key.public_key.to_pem
    save!
  end

  def jwk
    key = OpenSSL::PKey::RSA.new(tool_public_key)
    JWT::JWK.new(key, { alg: "RS256", use: "sig", kid: Digest::SHA256.hexdigest(tool_public_key) })
  end
end
