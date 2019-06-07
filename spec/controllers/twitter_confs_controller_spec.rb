require 'rails_helper'

describe TwitterConfsController do
  let(:ms) { MediaSource.create(
    description: 'needed to validate DataConfig',
    name: 'test',
    url: 'www.example.com'
  ) }
  let(:cfg) { DataConfig.create(keywords: ['foo', 'bar'], media_sources: [ms]) }

  it 'generates a conf file with the expected context' do
    # Easiest way to initialize the controller object with the params is to
    # call get.
    get :new, params: { id: cfg.id }, xhr: true

    expect(TwitterConf).to receive(:generate)
      .with(@controller.context)

    # Need to call get again to check the expectation.
    get :new, params: { id: cfg.id }, xhr: true
  end

  it 'calls File.write with the expected arguments' do
    get :new, params: { id: cfg.id }, xhr: true

    expect(File).to receive(:write)
      .with(TwitterConfsController::FILENAME,
            TwitterConf.generate(@controller.context)
      )
      get :new, params: { id: cfg.id }, xhr: true
  end
end
