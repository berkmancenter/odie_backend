class ApplicationController < ActionController::Base
  protect_from_forgery with: :null_session,
    if: Proc.new { |c| c.request.format == 'application/json' }
  respond_to :html, :json

  layout 'admin/application'

  def after_sign_in_path_for(resource)
  	stored_location_for(resource) || admin_root_path
  end
end
