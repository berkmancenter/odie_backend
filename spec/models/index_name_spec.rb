require 'rails_helper'

describe IndexName do
  it 'uses the provided prefix' do
    prefix = 'prefix'
    name = IndexName.new(prefix).generate
    expect(name).to start_with prefix
  end

  it 'randomizes' do
    prefix = 'prefix'
    name = IndexName.new(prefix).generate
    name2 = IndexName.new(prefix).generate
    expect(name).not_to eq name2
  end
end
