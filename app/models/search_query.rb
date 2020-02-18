# == Schema Information
#
# Table name: search_queries
#
#  id          :bigint           not null, primary key
#  active      :boolean
#  description :text
#  keywords    :string
#  name        :string
#  url         :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

require 'uri'

class SearchQuery < ApplicationRecord
  has_and_belongs_to_many :cohort_collectors

  validates :description, presence: true
  validates :name, presence: true
  validates :url_is_url

  after_save :guess_keyword

  # url setter removes protocol if present, so PublicSuffix can assume it is
  # getting the format it expects.
  def url=(val)
    # URI.encode is important to handle non-ASCII URLs. Twitter requires that
    # terms be urlencoded before search.
    parsed_url = URI.parse(URI.encode(val))
    new_val = if [parsed_url.kind_of?(URI::HTTPS),
                  parsed_url.kind_of?(URI::HTTP)].any?
                parsed_url.host
              else
                val
              end
    super(new_val)
  end

  def latest_data
    data_sets.last
  end

  private

  def url_is_url
    URI.parse(url)
  rescue URI::InvalidURIError
    errors.add(:url, 'Must be a valid URL')
  end

  def guess_keyword
    return if keyword.present? # don't override user choices

    self.update_attribute(:keyword, PublicSuffix.parse(url).sld)
  end
end
