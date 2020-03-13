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
#  index_sources_on_canonical_host  (canonical_host)
#  index_sources_on_variant_hosts   (variant_hosts) USING gin
#

class Source < ApplicationRecord
end
