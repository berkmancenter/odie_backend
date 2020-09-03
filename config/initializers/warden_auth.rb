Warden::JWTAuth.configure do |config|
  config.secret = ENV['DEVISE_JWT_SECRET_KEY']
  config.dispatch_requests = [
    ['POST', %r{^/login$}],
    ['POST', %r{^/login.json$}]
  ]
  config.revocation_requests = [
    ['DELETE', %r{^/logout$}],
    ['DELETE', %r{^/logout.json$}]
  ]
end
