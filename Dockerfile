# syntax = docker/dockerfile:1
ARG RUBY_VERSION=3.2.2
FROM registry.docker.com/library/ruby:$RUBY_VERSION-slim as base

WORKDIR /rails

# 開発のしやすさを優先し、デプロイモードを一時的に解除
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="0" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development"

# --- ビルドステージ ---
FROM base as build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev libvips pkg-config

ENV BUNDLE_FROZEN="false"

COPY Gemfile Gemfile.lock ./
RUN bundle config unset deployment && \
    bundle install && \
    bundle lock --add-platform aarch64-linux

COPY . .

# binフォルダをBundler対応に強制書き換え
RUN chmod +x bin/* && \
    bundle binstubs railties --force

RUN bundle exec bootsnap precompile app/ lib/
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# --- 実行ステージ ---
FROM base

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libvips postgresql-client && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# ビルド成果物のコピー
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /rails /rails

# パスの設定：アプリのbinを最優先にする（これで rails c が直打ち可能に！）
ENV BUNDLE_PATH="/usr/local/bundle"
ENV PATH="/rails/bin:/usr/local/bundle/bin:${PATH}"
ENV BUNDLE_DEPLOYMENT="0"

# ユーザー作成と権限設定（ここが重要です！）
RUN useradd rails --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp && \
    rm -rf .bundle/config

USER rails:rails

ENTRYPOINT ["/rails/bin/docker-entrypoint"]
EXPOSE 3000
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]
