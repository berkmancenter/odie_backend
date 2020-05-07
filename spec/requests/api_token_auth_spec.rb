require 'rails_helper'
require 'devise/jwt/test_helpers'

describe 'API token auth', type: :request do
  let(:user) { create(:user, password: 'api_test') }
  let(:headers) do
    {
      'Accept' => 'application/json',
      'Content-Type' => 'application/json'
    }
  end

  context 'checking auth' do
    before :all do
      create_list(:cohort, 3)
    end

    after :all do
      Cohort.destroy_all
    end

    it 'will return 401 with no auth token provided' do
      get cohorts_path, headers: headers
      expect(response.status).to eq 401
    end

    it 'will return 200 with valid auth token provided' do
      auth_headers = Devise::JWT::TestHelpers.auth_headers(headers, user)
      get cohorts_path, headers: auth_headers
      expect(response.status).to eq 200
      expect(response.body).to eq(
        CohortSerializer.new(Cohort.all).serialized_json
      )
    end
  end
end
