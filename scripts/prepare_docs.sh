if ! which bundle &> /dev/null; then
  gem install bundler --no-document || echo "failed to install bundle";
fi

if ! bundle info jazzy &> /dev/null; then
  bundle config set deployment 'true';
  bundle install || echo "failed to install bundle";
fi

bundle exec jazzy \
	--module Zone5 \
    --swift-build-tool xcodebuild \
    --build-tool-arguments -scheme,Zone5,-destination,'generic/platform=iOS Simulator' \
	--min-acl public \
	--hide-documentation-coverage \
	--title "Zone5 SDK for Swift" \
	--author_url https://zone5ventures.com \
	--github_url https://github.com/Zone5-Cloud/z5-sdk-swift \
	--theme fullwidth \
	--output ./docs
