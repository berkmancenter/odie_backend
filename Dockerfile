FROM ruby:2.6.3

RUN apt-get update && apt-get -y install nodejs tzdata git sqlite build-essential patch ruby-dev zlib1g-dev liblzma-dev default-jre
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - \
        && apt-get install -y nodejs

# Install Logstash
RUN wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add - && \
    apt-get install apt-transport-https && \
    echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-7.x.list && \
    apt-get update && apt-get install logstash && \
    export PATH=$PATH:/usr/share/logstash/bin

# Install Chrome
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
    echo 'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' | tee /etc/apt/sources.list.d/google-chrome.list && \
    apt-get update && apt-get install google-chrome-stable -y

RUN mkdir /app
WORKDIR /app

COPY . .
RUN bundle install

#CMD (while true; do sleep 1; done;)
CMD puma -C config/puma.rb
