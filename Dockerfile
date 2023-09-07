FROM ruby:3.2.2-alpine AS builder

RUN \
	apk update && apk upgrade && \
	apk --no-cache add build-base git gcompat ruby-dev ruby-bundler && \
	rm -rf /var/cache/apk/*

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock .ruby-version ./
ENV BUNDLER_WITHOUT="development test"
ENV BUNDLE_DEPLOYMENT="true"
RUN gem install bundler && bundle install
RUN rm -rf vendor/bundle/ruby/*/cache/

FROM ruby:3.2.2-alpine

RUN \
	apk update && apk upgrade && \
	apk --no-cache add git gcompat && \
	rm -rf /var/cache/apk/*

WORKDIR /usr/src/app
COPY --from=builder /usr/src/app/vendor/ ./vendor/
COPY Gemfile Gemfile.lock .ruby-version Procfile config.ru Dockerfile ./

ENV BUNDLER_WITHOUT="development test"
ENV BUNDLE_DEPLOYMENT="true"
RUN gem install bundler && bundle install

CMD ["bundle", "exec", "rackup"]
