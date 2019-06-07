require 'rails_helper'

feature 'Admin' do
  include Devise::Test::IntegrationHelpers
  let(:admin_user) { User.new(email: 'admin@exmaple.com', admin: true) }
  let(:api_user) { User.new(email: 'api@exmaple.com', admin: false) }

  scenario 'unauthed users see a sign-in form' do
    visit admin_root_path
    expect(page).to have_css "form[action='#{new_user_session_path}']"
  end

  scenario 'admin users can sign in to the admin' do
    sign_in admin_user
    visit admin_root_path
    expect(page.status_code).to equal 200
  end

  scenario 'non-admin users cannot sign in to the admin' do
    sign_in api_user
    skip 'need to make a home page to redirect api users to'
    visit admin_root_path
    assert_redirected_to '/'
  end

  scenario 'there is a sign-in form on the main page' do
    visit root_path
    expect(page).to have_css "form[action='#{new_user_session_path}']"
  end

  scenario 'there is a sign-out link on the admin page' do
    sign_in admin_user
    visit admin_root_path
    expect(page).to have_css('a', text: 'Sign Out')
  end
end
