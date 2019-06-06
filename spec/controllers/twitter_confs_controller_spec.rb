require 'rails_helper'

describe TwitterConfsController do
  fixtures :data_configs

  it 'generates a conf file with the expected context' do
    config = data_configs(:one)

    # Easiest way to initialize the controller object with the params is to
    # call get.
    get :new, params: { id: config.id }, xhr: true

    expect(TwitterConf).to receive(:generate)
      .with(@controller.context)

    # Need to call get again to check the expectation.
    get :new, params: { id: config.id }, xhr: true
  end

  it 'calls File.write with the expected arguments' do
    config = data_configs(:one)

    get :new, params: { id: config.id }, xhr: true

    expect(File).to receive(:write)
      .with(TwitterConfsController::FILENAME,
            TwitterConf.generate(@controller.context)
      )
    get :new, params: { id: config.id }, xhr: true
  end
end
