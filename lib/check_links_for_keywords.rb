# See https://www.elastic.co/guide/en/logstash/6.6/plugins-filters-ruby.html
# for documentation about these functions.
def register(params); end

def filter(event)
  if includes_any_target? event
    return [event]
  else
    return []
  end
end

def includes_any_target?(event)
  event.get('entities')['urls'].each do |u|
    ['washingtonpost', 'nytimes'].any? { |word| u['expanded_url'].include?(word) }
  end.any?
end
