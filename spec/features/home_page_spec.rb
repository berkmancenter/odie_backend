require 'rails_helper'

feature 'Home page' do
  context 'anonymous users' do
    it 'are prompted to log in' do
      user = create(:user, :admin, password: 'password')

      visit home_path

      expect(current_path).to eq new_user_session_path

      fill_in 'Email', with: user.email
      fill_in 'Password', with: 'password'
      click_button 'Log in'

      expect(current_path).to eq home_path
    end
  end

  context 'authenticated users' do
    before :each do
      login_as(create(:user, :admin))
    end

    it 'can stay on the home page' do
      visit '/'
      expect(current_path).to eq home_path
    end

    it 'sees links to search_queries' do
      visit '/'

      expect(page).to have_link('Search Queries', href: search_queries_path)
    end

    it 'sees links to cohort_collectors' do
      visit '/'

      expect(page).to have_link('Cohort Collectors', href: cohort_collectors_path)
    end
  end
end
