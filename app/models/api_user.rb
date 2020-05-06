class ApiUser < User
  include Devise::JWT::RevocationStrategies::Whitelist

  devise :jwt_authenticatable, jwt_revocation_strategy: self
  self.skip_session_storage = [:http_auth, :params_auth]
end
