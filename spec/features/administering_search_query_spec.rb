require 'rails_helper'

feature 'Administering SearchQuery' do
  let(:sq) { create(:search_query) }

  it 'restricts to logged-in administrative users' do
    visit search_queries_path
    expect(current_path).to eq new_user_session_path

    visit new_search_query_path
    expect(current_path).to eq new_user_session_path

    visit search_query_path(sq)
    expect(current_path).to eq new_user_session_path
  end

  context 'when logged in' do
    before :each do
      login_as(create(:user, :admin))
    end

    context '/search_queries' do
      it 'lets you see a list of search queries' do
        sq  # force it to exist in scope
        sq2 = create(:search_query)

        visit search_queries_path

        expect(page).to have_link(href: search_query_path(sq))
        expect(page).to have_link(href: search_query_path(sq2))
      end

      it 'links to search query creation' do
        visit search_queries_path

        click_on 'Create new'

        expect(current_path).to eq new_search_query_path
      end
    end

    context '/search_queries/new' do
      it 'lets new search queries be created' do
        expect(SearchQuery.count).to eq 0

        visit new_search_query_path

        fill_in 'Name', with: 'test'
        fill_in 'Description', with: 'Testing is a really good idea'
        fill_in 'URL', with: 'https://www.sandimetz.com/'
        click_on 'Create'

        latest = SearchQuery.last
        expect(latest.name).to eq 'test'
        expect(latest.description).to eq 'Testing is a really good idea'
        expect(latest.url).to eq 'www.sandimetz.com'  # normalized
        expect(SearchQuery.count).to eq 1
      end
    end

    context '/search_queries/X' do
      it 'shows you the search query' do
        visit search_query_path(sq)

        expect(page).to have_text sq.name
        expect(page).to have_text sq.url
        expect(page).to have_text sq.description
        expect(page).to have_text sq.keyword
      end
    end
  end
end
