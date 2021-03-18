FROM ruby:2.4

WORKDIR /app

COPY . /app
RUN gem install bundler -v=2.1.4 && \
    bundle install && \
    mkdir -p bind /app/tmp/puma

CMD ["bundle", "exec", "puma", "-C", "puma.rb"]
