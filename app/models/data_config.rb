# == Schema Information
#
# Table name: data_configs
#
#  id         :bigint           not null, primary key
#  index_name :string
#  keywords   :string           is an Array
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

# Works with TwitterConfsController to govern the creation of logstash conf
# files for the streaming API, and Rails model instances that collect data
# through the user timeline API.
class DataConfig < ApplicationRecord
  has_and_belongs_to_many :media_sources
  validates :media_sources, presence: true
  before_create :initialize_keywords

  def manufacture_data_sets
    media_sources.each do |media_source|
      DataSet.create(media_source: media_source)
    end
  end

  private

  # This freezes the keywords as they existed at the time of the configuration,
  # to aid in debugging. It also allows for collaborators to query DataConfig
  # directly for keywords rather than reaching through it to MediaSource.
  def initialize_keywords
    keywords = media_sources.pluck(:keywords)
  end

  # functions
  # clone function to create a new one with the same params
end
