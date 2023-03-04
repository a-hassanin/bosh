#!/usr/bin/env bash

set -e

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
bosh_path="${bosh_release_path:-${script_dir}/../../../}"
bosh_release_path=""
src_dir="${script_dir}/../../../"

pushd "${bosh_path}" > /dev/null
  if [[ ! -e $(find . -maxdepth 1 -name "*.tgz") ]]; then
    bosh reset-release
    bosh create-release --force --tarball release.tgz
  fi

  bosh_release_path="$(realpath "$(find . -maxdepth 1 -name "*.tgz")")"
popd > /dev/null

bosh upload-release ${bosh_release_path} --name=bosh

pushd "${src_dir}/src/go/src/github.com/cloudfoundry/bosh-release-acceptance-tests/assets/linked-templates-release" > /dev/null
  if [[ ! -e $(find . -maxdepth 1 -name "*.tgz") ]]; then
    bosh reset-release
    bosh create-release --force --tarball release.tgz
  fi
popd > /dev/null
