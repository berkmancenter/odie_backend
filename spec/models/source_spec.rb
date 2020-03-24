# == Schema Information
#
# Table name: sources
#
#  id             :bigint           not null, primary key
#  canonical_host :string
#  variant_hosts  :string           is an Array
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_sources_on_canonical_host  (canonical_host) UNIQUE
#  index_sources_on_variant_hosts   (variant_hosts) USING gin
#

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
