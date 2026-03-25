class Lti13Controller < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:login, :launch]
  before_action :check_lti13_enabled

  # GET/POST /lti13/login — OIDC Login Initiation
  def login
    platform = LtiPlatform.find_by(issuer: params[:iss], client_id: params[:client_id])
    return render json: { error: "Unknown LTI platform" }, status: :not_found unless platform

    state = SecureRandom.uuid
    nonce = SecureRandom.uuid

    session[:lti13_state] = state
    session[:lti13_nonce] = nonce

    auth_params = {
      scope: "openid",
      response_type: "id_token",
      client_id: platform.client_id,
      redirect_uri: lti13_launch_url,
      login_hint: params[:login_hint],
      lti_message_hint: params[:lti_message_hint],
      state: state,
      nonce: nonce,
      response_mode: "form_post",
      prompt: "none"
    }

    redirect_to "#{platform.auth_endpoint}?#{auth_params.to_query}", allow_other_host: true
  end

  # POST /lti13/launch — JWT Launch Callback
  def launch
    unless params[:state] == session.delete(:lti13_state)
      return render json: { error: "Invalid state parameter" }, status: :forbidden
    end

    claims = verify_and_decode_jwt(params[:id_token])

    unless claims["nonce"] == session.delete(:lti13_nonce)
      return render json: { error: "Invalid nonce" }, status: :forbidden
    end

    message_type = claims["https://purl.imsglobal.org/spec/lti/claim/message_type"]

    case message_type
    when "LtiResourceLinkRequest"
      handle_resource_link(claims)
    when "LtiDeepLinkingRequest"
      handle_deep_linking(claims)
    else
      render json: { error: "Unsupported message type: #{message_type}" }, status: :bad_request
    end
  end

  # GET /lti13/jwks — Tool's public JWKS endpoint
  def jwks
    keys = LtiPlatform.all.map(&:jwk).compact
    render json: { keys: keys.map(&:export) }
  end

  private

  def check_lti13_enabled
    unless Flipper.enabled?(:lti_v13_integration)
      render json: { error: "LTI 1.3 is not enabled" }, status: :not_found
    end
  end

  def verify_and_decode_jwt(id_token)
    # Decode header to find issuer without verification first
    unverified = JWT.decode(id_token, nil, false).first
    platform = LtiPlatform.find_by!(issuer: unverified["iss"])

    # Fetch platform's public keys
    response = HTTParty.get(platform.public_key_set_url)
    jwk_set = JWT::JWK::Set.new(JSON.parse(response.body))

    # Verify signature, audience, and issuer
    JWT.decode(id_token, nil, true, {
      algorithms: ["RS256"],
      jwks: jwk_set,
      verify_aud: true,
      aud: platform.client_id,
      verify_iss: true,
      iss: platform.issuer
    }).first
  end

  def handle_resource_link(claims)
    context = claims["https://purl.imsglobal.org/spec/lti/claim/context"]
    resource = claims["https://purl.imsglobal.org/spec/lti/claim/resource_link"]

    # Store user's LTI sub claim for AGS grade passback
    lti_user_id = claims["sub"]

    # Find or create user session, redirect to assignment
    # (Implementation connects to existing CircuitVerse auth flow)
    redirect_to root_path  # placeholder — will route to assignment
  end

  def handle_deep_linking(claims)
    # Return assignment picker UI for instructors
    render json: { message: "Deep linking UI placeholder" }
  end
end
