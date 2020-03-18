require 'rails_helper'

describe Source do
  before :all do
    @source = create(:source)
  end

  it 'finds an instance given a canonical url' do
    expect(Source.find_by_url('nytimes.com').id).to eq @source.id
  end

  it 'finds an instance given a variant url' do
    expect(Source.find_by_url('nyti.ms').id).to eq @source.id
  end

  it 'canonicalizes known urls' do
    expect(Source.canonicalize('nyti.ms')).to eq 'nytimes.com'
  end

  it 'leaves unknown urls alone when canonicalizing' do
    assert Source.find_by_url('timecube.com') == nil
    expect(Source.canonicalize('timecube.com')).to eq 'timecube.com'
  end
end
