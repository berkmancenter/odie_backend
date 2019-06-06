# == Schema Information
#
# Table name: media_sources
#
#  id          :bigint           not null, primary key
#  active      :boolean
#  description :text
#  keyword     :string
#  name        :string
#  url         :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class MediaSource < ApplicationRecord
  has_many :data_sets
  has_and_belongs_to_many :data_configs

  validates :description, presence: true
  validates :name, presence: true
  validates :url, presence: true

  after_save :guess_keyword

  # url setter removes protocol if present, so PublicSuffix can assume it is
  # getting the format it expects.
  def url=(val)
    parsed_url = URI.parse(val)
    new_val = if [parsed_url.kind_of?(URI::HTTPS),
                  parsed_url.kind_of?(URI::HTTP)].any?
                parsed_url.host
              else
                val
              end
    super(new_val)
  end

  private

  def guess_keyword
    return if keyword.present? # don't override user choices

    self.update_attribute(:keyword, PublicSuffix.parse(url).sld)
  end
end
