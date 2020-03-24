class WordExtractor < Extractor  
  EXTRA_STOPWORDS = ['rt', '&amp;']

  private

  # This is made case-insensitive by downcasing everything. That's a bummer;
  # it would be better for the stopword filter to be case-insensitive.
  def extract
    users_and_words = []
    @tweets.each do |tweet|
      users_and_words += sw_filter(tweet.lang)
                         .filter(tweet.attrs[:full_text].split.map { |w| w.downcase } )
                         .map { |w| [tweet.user.id, w] }
    end

    users_and_words
      .uniq { |user_and_word| [user_and_word[0], user_and_word[1]] }
      .map { |user_and_word| user_and_word[1] }
      .each do |token|
        next unless is_word? token
        @all_things[token] += 1 unless token.nil?
      end
  end

  def is_word?(token)
    [token.starts_with?('#'),
     token.starts_with?('http')].none?
  end

  def sw_filter(lang)
    begin
      Stopwords::Snowball::Filter.new(lang, EXTRA_STOPWORDS)
    rescue ArgumentError # if language was invalid, default to English
      Stopwords::Snowball::Filter.new('en', EXTRA_STOPWORDS)
    end
  end
end
