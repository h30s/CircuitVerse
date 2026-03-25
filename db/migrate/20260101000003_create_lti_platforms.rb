class CreateLtiPlatforms < ActiveRecord::Migration[8.0]
  def change
    create_table :lti_platforms do |t|
      t.string  :issuer,             null: false
      t.string  :client_id,          null: false
      t.string  :deployment_id
      t.text    :public_key_set_url                  # Platform JWKS
      t.string  :auth_endpoint                       # OIDC auth URL
      t.string  :token_endpoint                      # OAuth2 token URL
      t.text    :tool_private_key                    # RSA private key (encrypted)
      t.text    :tool_public_key                     # RSA public key
      t.references :group, foreign_key: true, null: true
      t.timestamps
    end

    add_index :lti_platforms, [:issuer, :client_id], unique: true
  end
end
