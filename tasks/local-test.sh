#!/usr/bin/env bash
# Copyright (c) 2015-present, Facebook, Inc.
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

function print_help {
  echo "Usage: ${0} [OPTIONS]"
  echo ""
  echo "OPTIONS:"
  echo "  --node-version <version>  the node version to use while testing [6]"
  echo "  --git-branch <branch>     the git branch to checkout for testing [the current one]"
  echo "  --test-suite <suite>      which test suite to use ('simple', installs', 'kitchensink', 'all') ['all']"
  echo "  --interactive             gain a bash shell after the test run"
  echo "  --help                    print this message and exit"
  echo ""
}

cd $(dirname $0)

node_version=6
current_git_branch=`git rev-parse --abbrev-ref HEAD` # this will get the branch name
git_branch=${current_git_branch}
test_suite=all
interactive=false

while [ "$1" != "" ]; do
  case $1 in
    "--node-version")
      shift
      node_version=$1
      ;;
    "--git-branch")
      # this will re-position the argument.
      # For instance, "./local-test.sh --git-branch master"
      # will shift from "--git-branch" to "master", and $1 becomes "master"
      shift
      git_branch=$1
      ;;
    "--test-suite")
      shift
      test_suite=$1
      ;;
    "--interactive")
      interactive=true
      ;;
    "--help")
      print_help
      exit 0
      ;;
  esac
  shift
done

test_command="./tasks/e2e-simple.sh && ./tasks/e2e-kitchensink.sh && ./tasks/e2e-installs.sh && ./tasks/e2e-monorepos.sh"
case ${test_suite} in
  "all")
    ;;
  "simple")
    test_command="./tasks/e2e-simple.sh"
    ;;
  "kitchensink")
    test_command="./tasks/e2e-kitchensink.sh"
    ;;
  "installs")
    test_command="./tasks/e2e-installs.sh"
    ;;
  "monorepos")
    test_command="./tasks/e2e-monorepos.sh"
    ;;
  *)
    ;;
esac

# this will read the CMD block
# and put it to an variable "$apply_changes"
# -r: Do not let backslash (\) act as an escape character
# -d: Use a specific character as a delimiter instead of a new line
read -r -d '' apply_changes <<- CMD
cd /var/create-react-app
git config --global user.name "Create React App"
git config --global user.email "cra@email.com"
git stash save -u
git stash show -p > patch
git diff 4b825dc642cb6eb9a060e54bf8d69288fbee4904 stash^3 >> patch
git stash pop
cd -
mv /var/create-react-app/patch .
git apply patch
rm patch
CMD

if [ ${git_branch} != ${current_git_branch} ]; then
  apply_changes=''
fi

read -r -d '' command <<- CMD
echo "prefix=~/.npm" > ~/.npmrc
mkdir ~/.npm
export PATH=\$PATH:~/.npm/bin
set -x
git clone /var/create-react-app create-react-app --branch ${git_branch}
cd create-react-app
${apply_changes}
node --version
npm --version
set +x
${test_command} && echo -e "\n\e[1;32m✔ Job passed\e[0m" || echo -e "\n\e[1;31m✘ Job failed\e[0m"
$([[ ${interactive} == 'true' ]] && echo 'bash')
CMD
# run command, if success show "Job passed", else show "Job failed"
# echo -e: Enable interpretation of backslash escapes (special characters)
# ${test_command} && echo -e "\n\e[1;32m✔ Job passed\e[0m" || echo -e "\n\e[1;31m✘ Job failed\e[0m"

docker run \
  --env CI=true \
  --env NPM_CONFIG_QUIET=true \
  --tty \
  --user node \
  --volume ${PWD}/..:/var/create-react-app \
  --workdir /home/node \
  $([[ ${interactive} == 'true' ]] && echo '--interactive') \
  node:${node_version} \
  bash -c "${command}"
