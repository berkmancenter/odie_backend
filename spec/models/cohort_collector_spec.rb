describe CohortCollector do
  it 'gets the right number of users when there are many to sample from' do
    pending 'This was moved from the old DataSet and needs to be updated'
    # Mock out collaborators.
    allow_any_instance_of(Elasticsearch::API::Actions)
      .to receive(:search)
    # Assert initial conditions.
    expect(ds.num_users).to 100
    # Test.
    ds.sample_users
    expect(ds.sample_users.length).to eq Rails.application.config.num_users
  end

  it 'samples distinct user ids' do
    pending 'This was moved from the old DataSet and needs to be updated'
    allow_any_instance_of(Elasticsearch::API::Actions)
      .to receive(:search)
    allow(ds).to receive(:extract_userids)
      .and_return [1, 2, 2, 3, 3]
    # Assert initial conditions.
    expect(ds.num_users).to be_nil
    # Test.
    expect(ds.sample_users).to match_array [1, 2, 3]
  end
end
