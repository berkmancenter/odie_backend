require 'rails_helper'

describe TwitterConfsController do
  let(:ms) { build(:media_source) }
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

  it 'urlencodes with non-ascii characters' do
    nonascii = DataConfig.create(
      keywords: ['ümlauts', 'ácutes', '汉字', '훈민정음'],
      media_sources: [ms])

    get :new, params: { id: nonascii.id }, xhr: true

    expect(@controller.context.local_variable_get :keywords)
      .to contain_exactly("%C3%BCmlauts", "%C3%A1cutes",
                          "%E6%B1%89%E5%AD%97",
                          "%ED%9B%88%EB%AF%BC%EC%A0%95%EC%9D%8C")
  end
end
