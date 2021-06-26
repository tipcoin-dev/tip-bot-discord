FROM ruby:2.7.2

ENV APP_HOME=/opt/app
ENV BUNDLER_VERSION=2.2.20

RUN apt-get update -qq && apt-get install -y build-essential libpq-dev libxml2-dev libxslt1-dev

RUN mkdir -p $APP_HOME
WORKDIR $APP_HOME

RUN echo "gem: --no-document" > ~/.gemrc
RUN gem install bundler:$BUNDLER_VERSION
ADD Gemfile* $APP_HOME/

RUN bundle install -j2

ADD . $APP_HOME

CMD ["bundle", "exec", "ruby", "main.rb"]