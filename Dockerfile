FROM ruby:2.6.3

RUN apt-get update && apt-get -y install nodejs tzdata git sqlite build-essential patch ruby-dev zlib1g-dev liblzma-dev default-jre
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - \
        && apt-get install -y nodejs
RUN wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add - && \
    apt-get install apt-transport-https && \
    echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-7.x.list && \
    apt-get update && apt-get install logstash

RUN mkdir /app
WORKDIR /app

COPY . .
RUN bundle install

CMD puma -C config/puma.rb
