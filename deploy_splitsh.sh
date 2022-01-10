#!/bin/bash
#
# This script automates the creation and updating of a subtree split
# in a second repository.
#
set -eu
ARG1=0.3

# command -v splitsh-lite >/dev/null 2>&1 || { echo "$0 requires splitsh-lite but it's not installed.  Aborting." >&2; exit 1; }

source_repository=git@github.com:rgarnica/poc-symfony-monorepo.git
source_branch=0.3

typeset -A components

while IFS== read -r path repo; do
    components["$path"]="$repo"
done < <(jq -r '.[] | .path + "=" + .repo ' repositories.json)

for K in "${!components[@]}";
do
  echo -e "\n${components[$K]}\n"
  # The rest shouldn't need changing.
  temp_repo=$(mktemp -d)
  # shellcheck disable=SC2002
  temp_branch=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 30 | head -n 1)

  echo "hey"
  echo $temp_branch

  # Checkout the old repository, make it safe and checkout a temp branch
  git clone ${source_repository} "${temp_repo}"
  cd "${temp_repo}"
  git checkout "${source_branch}"
  git remote remove origin
  git checkout -b "${temp_branch}"

  sha1=$(splitsh-lite --prefix="${K}" --quiet)
  git reset --hard "${sha1}"
  git remote add remote "${components[$K]}"
  git push -u remote "${temp_branch}":"${source_branch}" --force
  git remote rm remote

  ## Cleanup
  cd /tmp
  rm -rf "${temp_repo}"
done