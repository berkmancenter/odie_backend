require 'rails_helper'

feature 'Administering CohortCollector' do
  let(:cc) { create(:cohort_collector) }

  it 'restricts to logged-in administrative users' do
    visit cohort_collectors_path
    expect(current_path).to eq new_user_session_path

    visit new_cohort_collector_path
    expect(current_path).to eq new_user_session_path

    visit cohort_collector_path(cc)
    expect(current_path).to eq new_user_session_path
  end

  context 'when logged in' do
    before :each do
      login_as(create(:user, :admin))
    end

    context '/cohort_collectors' do
      it 'lets you see a list of cohort collectors' do
        cc  # force it to exist in scope
        cc2 = create(:cohort_collector)

        visit cohort_collectors_path

        expect(page).to have_link(href: cohort_collector_path(cc))
        expect(page).to have_link(href: cohort_collector_path(cc2))
      end

      it 'links to new cohort collector creation' do
        visit cohort_collectors_path

        click_on 'Create new'

        expect(current_path).to eq new_cohort_collector_path
      end
    end

    context '/cohort_collectors/new' do
      it 'allows for new cohort collectors to be created' do
        expect(CohortCollector.count).to eq 0
        sq = create(:search_query)

        visit new_cohort_collector_path

        find 'select'
        select sq.url
        click_on 'Create'

        latest = CohortCollector.last
        expect(latest.search_queries).to eq [sq]
        expect(CohortCollector.count).to eq 1
      end
    end

    context '/cohort_collectors/X' do
      it 'lets you kick off a streaming twitter data collection run', js: true do
        sdf = instance_double(StreamingDataCollector)
        allow(sdf).to receive(:write_conf)
        sdf.stub(:kickoff)  # don't actually start logstash
        allow(StreamingDataCollector).to receive(:new).with(cc).and_return(sdf)

        expect(sdf).to receive :kickoff

        visit cohort_collector_path(cc)
        click_on 'Start collecting data'
      end

      it 'shows if a data collection run is currently in progress' do
        # No run
        cc.update_attributes(start_time: nil, end_time: nil)

        visit cohort_collector_path(cc)
        expect(page).to have_text 'Data collection run in progress? no'

        # Run not yet started
        cc.update_attributes(
          start_time: Time.now + 10.minutes, end_time: Time.now + 20.minutes)

        visit cohort_collector_path(cc)
        expect(page).to have_text 'Data collection run in progress? no'

        # Run in process
        cc.update_attributes(
          start_time: Time.now - 10.minutes, end_time: Time.now + 10.minutes)

        visit cohort_collector_path(cc)
        expect(page).to have_text 'Data collection run in progress? yes'

        # Run concluded
        cc.update_attributes(
          start_time: Time.now - 20.minutes, end_time: Time.now - 10.minutes)

        visit cohort_collector_path(cc)
        expect(page).to have_text 'Data collection run in progress? no'
      end

      it 'lets you create cohorts when creation is permissible', js: true do
        good_cc = create(:cohort_collector, :creation_permissible)
        allow_any_instance_of(CohortCollector).to receive(:sample_users)
                                              .and_return(['14706139'])

        expect(Cohort).to receive(:create)

        visit cohort_collector_path(good_cc)
        click_on 'Create cohort'
      end

      it 'does not show the cohort creation option when creation is not permissible' do
        visit cohort_collector_path(cc)

        expect(page).not_to have_text 'Create cohort'
      end
    end
  end
end
