require 'test_helper'

class AdminFlowTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'unauthed users are presented with a sign-in form' do
    get admin_root_path
    assert_response :redirect
    follow_redirect!
    assert_select "form[action='#{new_user_session_path}']"
  end

  test 'admin users can sign in to the admin' do
    sign_in users(:admin)
    get admin_root_path
    assert_response :success
  end

  test 'non-admin users cannot sign in to the admin' do
    sign_in users(:api)
    get admin_root_path
    assert_response :redirect
  end

  test 'there is a sign-in form on the main page' do
    get root_path
    assert_select "form[action='#{new_user_session_path}']"
  end

  test 'there is a sign-out link on the admin page' do
    sign_in users(:admin)
    get admin_root_path
    assert_select 'a', 'Sign Out'
  end
end
