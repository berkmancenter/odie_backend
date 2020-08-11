# Shared logic for extracting aggregated metadata from tweets. This performs
# bookkeeping functions and is not intended to be invoked directly.
#
# The `harvest` method returns a hash of the top THRESHOLD most common
# elements of the given data type within the given set of tweets.
#
# Subclasses should define an `extract` method which has the type-specific logic
# for finding their metadata type (user mentions, hashtags, etc.)
#
# This class provides `all_nested` as a utility for its subclasses -- it pulls
# out all objects of the given type from the tweet and its retweeted or
# quoted tweets (since the top-level tweet object does not contain everything
# visible to users who are reading an actual timeline). Similarly it provides
# 'all_nested_with_user' to facilitate counting the number of distinct users
# who tweeted about a particular item.
#
# Extractors can also aggregate metadata of their type across multiple data
# sets. (This should really belong to a different class, but it's technical
# debt in the name of getting this done.) The expected workflow is
# self.accumulate.collate.
#
# `accumulate` combines data of a given type from multiple datasets.
# `collate` takes the combined data and rejects everything whose counts are
# insufficient.
class Extractor
  THRESHOLD = ENV['EXTRACTOR_THRESHOLD'] ? ENV['EXTRACTOR_THRESHOLD'].to_i : 5
  TOP_N  = ENV['EXTRACTOR_TOP_N'] ? ENV['EXTRACTOR_TOP_N'].to_i : 5

  def initialize(tweets)
    @tweets = tweets.flatten
    # @all_things will be used to report out final counts.
    @all_things = Hash.new 0
    # @working_space will be used to keep track of every mention of an object
    # by any user. Once we've accumulated them all, we'll postprocess to
    # count the number of users, and turn this into @all_things.
    # If we just set this to Hash.new [] we will be sad:
    # https://mensfeld.pl/2016/09/ruby-hash-default-value-be-cautious-when-you-use-it/
    @working_space = Hash.new { |hash, key| hash[key] = [] }
  end

  # Subclasses should define as the logic of extracting an object may be
  # type-specific.
  def extract; end

  def accumulate(data_sets)
    client = Elasticsearch::Client.new host: ENV['ELASTICSEARCH_HOST']
    @tweets = []

    # Rehydrate Tweet objects from Elasticsearch. Then we can use the extractors
    # in their usual fashion. The size argument guarantees we get all of the
    # tweets and may be terribly nonperformant -- scrolling may end up being
    # better, but this is very easy.
    data_sets.each do |ds|
      results = client.search index: ds.index_name, size: ds.num_tweets
      @tweets += results['hits']['hits'].map do |t|
        Twitter::Tweet.new(t['_source'].deep_symbolize_keys)
      end
    end

    self  # make method chainable
  end

  def collate
    # Only report the top N ranks (including ties), and don't report anything
    # below the threshold.
    min_count = @all_things.values.sort.last(TOP_N)[0]
    @all_things.reject { |k, v| v < [min_count, THRESHOLD].max }
  end

  def harvest
    extract
    set_all_things
    collate
  end

  private

  # Entity objects may be contained in the tweet, its retweeted tweet, or its
  # quoted tweet.
  def all_nested(obj_type, tweet)
    [tweet.send(obj_type),
     tweet.retweeted_status&.send(obj_type),
     tweet.retweeted_status&.quoted_status&.send(obj_type),
     tweet.quoted_status&.send(obj_type)]
  end

  def all_nested_with_user(obj_type, tweet)
    retval = []

    # flattening here lets us reject empty tweets, which means there's less
    # work for subclasses to do. And returning hashes with one item apiece,
    # rather than lists of all items corresponding to a user, also turns out
    # to simplify processing in subclasses.
    all_nested(obj_type, tweet).flatten.map do |nested|
      nested = nested.is_a?(Array) ? nested : [nested]
      nested.each { |n| retval << { item: n, user_id: tweet.user.id } }
    end

    retval
  end

  # In @working_space, we've kept track of every time we've seen an item, even
  # if a user has shared it more than once. In @all_things, we want to report
  # out counts of the number of unique users. Therefore we postprocess our
  # @working_space down to @all_things.
  def set_all_things
    @working_space.each do |item, user_ids|
      @all_things[item] = user_ids.uniq.length
    end
  end
end
