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

class Source < ApplicationRecord
  def self.find_by_url(url)
    self.canonical_source(url) || self.variant_source(url)
  end

  private

  def self.canonical_source(url)
    s = where(canonical_host: url)
    s.exists? ? s.first : nil
  end

  def self.variant_source(url)
    s = where("'{#{url}}' <@ variant_hosts")
    s.exists? ? s.first : nil
  end
end
