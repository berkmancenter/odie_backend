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

class MediaSourceSerializer
  include FastJsonapi::ObjectSerializer
  attributes :description, :name, :url

  attribute :latest_data do |obj|
    if (data = obj.latest_data)
      DataSetSerializer.new(data).serializable_hash
    else
      nil
    end
  end

  # Intended to be called when there is a collection of items. Returns the
  # regular serializable_hash plus aggregated data over the collection.
  def aggregated_hash
    aggregate_data = Hash.new(0)

    DataSetSerializer.attributes_to_serialize.keys.each do |key|
      aggregate_data[key] = aggregated_value(key)
    end

    base_hash[:aggregate_data] = aggregate_data
    base_hash
  end

  private

  def base_hash
    @base_hash ||= serializable_hash
  end

  # Pulls out the data hash from the base hash since we'll be using it a lot.
  def data_hash
    @data_hash ||= base_hash[:data]
  end

  # Extracts data for a specific item in a collection. A convenience method
  # rather than needing to write out the whole mess.
  def item_data(hsh)
    hsh[:attributes][:latest_data][:data][:attributes]
  end

  def all_values_for_key(key)
    puts key
    puts data_hash
    data_hash.map { |item| item_data(item) }.map { |d| d[key] }
  end

  # Aggregates all values for a given key in each hash in an array of hashes.
  # For string values, this means returning them unchanged.
  # For integer values, it sums them.
  # For hash values ({key: integer}), it returns a hash whose keys are all the
  # keys contained in any of the hashes, and whose values are the sum across
  # all hashes for that key.
  def aggregated_value(key)
    values = all_values_for_key(key)

    case values[0]
    when String
      values
    when Integer
      values.reduce(0, :+)
    when Hash
      aggregate_hashes(values)
    end
  end

  def aggregate_hashes(values)
    all_things = values.reduce {
      |first, second| first.merge(second) {
        |key, first_val, second_val| first_val.to_i + second_val.to_i
      }
    }.transform_values { |v| v.to_i }

    cut_below_threshold(all_things)
  end

  # Copy-pasted from Extractor. If we use this again it needs to be DRYer.
  def cut_below_threshold(all_things)
    candidates = all_things.values.sort[Extractor::THRESHHOLD]
    if candidates
      all_things.reject { |k, v| v < candidates }
    else
      all_things
    end
  end
end
