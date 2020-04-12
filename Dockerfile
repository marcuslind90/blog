FROM ruby:2.7.1

WORKDIR /app/

COPY . /app

RUN gem install bundler jekyll && bundle && bundle install

CMD bundle exec jekyll serve --host=0.0.0.0
