require 'rails_helper'

feature 'Admin' do
  include Devise::Test::IntegrationHelpers
  let(:admin_user) { build(:user, :admin) }
  let(:api_user) { build(:user) }

  context 'unauthenticated users' do
    scenario 'are prompted to sign in if they visit the admin' do
      visit admin_root_path
      expect(page).to have_css "form[action='#{new_user_session_path}']"
    end

    scenario 'see a sign-in form on the main page' do
      visit root_path
      expect(page).to have_css "form[action='#{new_user_session_path}']"
    end
  end

  context 'admin users' do
    scenario 'can sign in to the admin' do
      sign_in admin_user
      visit admin_root_path
      expect(page.status_code).to equal 200
    end

    scenario 'can see a sign-out link on the admin page' do
      sign_in admin_user
      visit admin_root_path
      expect(page).to have_css('a', text: 'Sign Out')
    end
  end

  context 'non-admin users' do
    scenario 'cannot view the admin' do
      sign_in api_user
      visit admin_root_path
      expect(current_path).to eq root_path  # ie user was redirected
    end
  end
end
