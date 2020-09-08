class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception, unless: :json_request?
  protect_from_forgery with: :null_session, if: :json_request?
  skip_before_action :verify_authenticity_token, if: :json_request?
  respond_to :html, :json

  rescue_from ActionController::InvalidAuthenticityToken,
              with: :invalid_auth_token

  before_action :set_current_user, if: :json_request?
  before_action :authenticate_user!, except: :cors_preflight_check
  after_action  :cors_set_access_control_headers

  layout 'application'

  def cors_preflight_check
    return unless request.method == 'OPTIONS'

    set_cors_headers
    render plain: '', content_type: 'text/plain'
  end

  private

  def json_request?
    request.format.json?
  end

  # Use api_user Devise scope for JSON access
  def authenticate_user!(*args)
    super && return unless args.blank?
    super && return if json_request? && !warden.authenticate(scope: :api_user)
    json_request? ? authenticate_api_user! : super
  end

  def invalid_auth_token
    respond_to do |format|
      format.html {
        redirect_to sign_in_path, error: 'Login invalid or expired'
      }
      format.json { head 401 }
    end
  end

  # So we can use Pundit policies etc. for api_users
  def set_current_user
    @current_user ||= warden.authenticate(scope: :api_user)
  end

  def cors_set_access_control_headers
    set_cors_headers
  end

  def set_cors_headers
    headers['Access-Control-Allow-Origin'] = ENV['CORS_ORIGIN'] || '*'
    headers['Access-Control-Allow-Methods'] = ENV['CORS_ALLOWED_METHODS'] ||
                                              'POST, GET, OPTIONS'
    headers['Access-Control-Allow-Headers'] = ENV['CORS_ALLOWED_HEADERS'] || '*'
    headers['Access-Control-Expose-Headers'] = ENV['CORS_EXPOSED_HEADERS'] ||
                                               '*'
  end
end
