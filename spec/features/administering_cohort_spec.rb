require 'rails_helper'

feature 'Administering Cohort' do
  let(:cohort) { create(:cohort) }

  context '#index' do
    context 'when logged in as admin' do
      before :each do
        login_as(create(:user, :admin))
      end

      it 'defaults to html' do
        visit cohorts_path

        expect(page).to have_http_status(200)
        expect(page.response_headers['Content-Type']).to include('text/html')
      end

      it 'lets you see json' do
        visit cohorts_path(format: :json)

        expect(page).to have_http_status(200)
        expect(page.response_headers['Content-Type']).to include('application/json')
      end

      it 'lets you see csv' do
        visit cohorts_path(format: :csv)

        expect(page).to have_http_status(200)
        expect(page.response_headers['Content-Type']).to include('text/csv')
      end

      it 'links to cohorts' do
        create_list(:cohort, 2)
        visit cohorts_path

        expect(page.body).to include(cohort_path(Cohort.last))
        expect(page.body).to include(cohort_path(Cohort.second_to_last))
      end

      it 'links to new cohort creation' do
        visit cohorts_path

        expect(page.body).to include(new_cohort_path)
      end
    end

    context 'when logged in as an api user' do
      before :each do
        login_as(create(:user))
      end

      it 'defaults to json' do
        visit cohorts_path

        expect(page).to have_http_status(200)
        expect(page.response_headers['Content-Type']).to include('application/json')
      end
    end
  end

  context '#show' do
    before :all do
      create(:cohort)
    end

    after :all do
      Cohort.last.destroy
    end

    context 'when logged in as admin' do
      before :each do
        login_as(create(:user, :admin))
      end

      it 'defaults to html' do
        visit cohort_path(Cohort.last)

        expect(page).to have_http_status(200)
        expect(page.response_headers['Content-Type']).to include('text/html')
      end

      it 'lets you see json' do
        visit cohorts_path(Cohort.last, format: :json)

        expect(page).to have_http_status(200)
        expect(page.response_headers['Content-Type']).to include('application/json')
      end

      it 'lets you see json' do
        visit cohorts_path(Cohort.last, format: :csv)

        expect(page).to have_http_status(200)
        expect(page.response_headers['Content-Type']).to include('text/csv')
      end

      it 'shows metadata' do
        c = Cohort.last
        visit cohort_path(c)

        expect(page.body).to include(ERB::Util.html_escape(c.twitter_ids.to_s))
        expect(page.body).to include(ERB::Util.html_escape(c.description))
      end

      it 'lets you initiate data collection', js: true do
        visit cohort_path(Cohort.last)

        c = double('Cohort')
        allow(Cohort).to receive(:find).and_return(c)
        expect(c).to receive(:collect_data)

        click_on 'Start collecting data (may take a while...)'
      end
    end

    context 'when logged in as an api user' do
      before :each do
        login_as(create(:user))
      end

      it 'defaults to json' do
        visit cohort_path(Cohort.last)

        expect(page).to have_http_status(200)
        expect(page.response_headers['Content-Type']).to include('application/json')
      end
    end
  end

  context '#new' do
    it 'is only accessible to admin users' do
      login_as(create(:user))

      visit new_cohort_path
      expect(page).to have_http_status(401)
    end

    it 'lets you create a cohort' do
      login_as(create(:user, :admin))

      visit new_cohort_path

      fill_in 'Twitter IDs', with: '14706139, 19259102'
      fill_in 'Description', with: 'Some content'
      click_on 'Create'

      expect(Cohort.count).to eq 1
      expect(Cohort.last.twitter_ids).to eq ["14706139", "19259102"]
      expect(Cohort.last.description).to eq 'Some content'
    end
  end
end
