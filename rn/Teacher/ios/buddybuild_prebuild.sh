#!/usr/bin/env bash -e

sudo systemsetup -settimezone America/Denver
sudo systemsetup -gettimezone

retry_command() {
  # retry up to 3 times
  for try_count in {1..2}; do
    set +e

    "$@"
    command_exit_code=$?

    set -e

    if [[ ${command_exit_code} -ne 0 ]]; then
      # command should error if we're on the last attempt.
      if [[ ${try_count} = 2 ]]; then
        "$@"
      fi
      continue
    else
      break
    fi
  done
}

# buddybuild app settings are *not respected* in custom scripts.
# we have to manually install / retry / etc. all build commands

set +e
brew update &> /dev/null
brew upgrade yarn &> /dev/null
set -e

# https://github.com/tj/n
n 7.9.0

node_version_expected="v7.9.0"
node_version="$(node -v)"
echo "Using node: $node_version"
echo "Using carthage: $(carthage version)"

if [ "$node_version_expected" != "$node_version" ]; then
  echo "Node version mismatch. Expected $node_version_expected Got: $node_version"
  exit 1
fi

# Avoid flaky unit tests by skipping them on the UI job.
TEACHER_UI_JOB_ID=58c981b73749ca0100c1abb3
if [[ "$BUDDYBUILD_APP_ID" = $TEACHER_UI_JOB_ID ]]; then
  echo "Teacher UI job detected. Ending prebuild."
  exit 0
fi

pushd ../
retry_command yarn run lint
retry_command yarn run flow
mkdir -p "$BUDDYBUILD_WORKSPACE/buddybuild_artifacts/Jest"
retry_command yarn run test -- --coverage --outputFile="$BUDDYBUILD_WORKSPACE/buddybuild_artifacts/Jest/jest.json" --json

TEACHER_APP_ID=58b0b2116096900100863eb8

if [ "$BUDDYBUILD_BASE_BRANCH" != "" ] && [ "$BUDDYBUILD_APP_ID" = "$TEACHER_APP_ID" ]; then
    aws s3 cp --quiet s3://inseng-code-coverage/ios-teacher/coverage/coverage-summary.json ./coverage-summary-develop.json
    export DANGER_FAKE_CI="YEP"
    export DANGER_TEST_REPO="$BUDDYBUILD_REPO_SLUG"
    export DANGER_TEST_PR="$BUDDYBUILD_PULL_REQUEST"
    yarn run danger
fi

popd

