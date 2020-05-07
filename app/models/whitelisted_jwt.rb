# == Schema Information
#
# Table name: whitelisted_jwts
#
#  id      :bigint           not null, primary key
#  aud     :string
#  exp     :datetime         not null
#  jti     :string           not null
#  user_id :bigint           not null
#
# Indexes
#
#  index_whitelisted_jwts_on_jti      (jti) UNIQUE
#  index_whitelisted_jwts_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id) ON DELETE => cascade
#

class WhitelistedJwt < ApplicationRecord
end
