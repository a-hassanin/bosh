require 'common/retryable'
require 'open3'
require_relative './artifact'

module Bosh::Dev
  class GnatsdManager
    VERSION = 'latest'.freeze

    REPO_ROOT = File.expand_path('../../../../', File.dirname(__FILE__))
    INSTALL_DIR = File.join('tmp', 'gnatsd')
    EXECUTABLE_NAME = 'gnatsd'.freeze

    def self.install
      # just use bosh cli to sync blobs to get the latest nats package tarball for the current commit
      _, status = Open3.capture2("cd #{REPO_ROOT}/..; bosh sync-blobs;")
      raise 'error syncing bosh blobs' unless status.success?

      _, status = Open3.capture2("tar \
                                  -C #{REPO_ROOT}/#{INSTALL_DIR}/ \
                                  -xzf #{REPO_ROOT}/../blobs/nats/nats-server*.tar.gz \
                                  --wildcards nats-server-*/nats-server")
      raise "error extracting nats binary to #{REPO_ROOT}/#{INSTALL_DIR}" unless status.success?

      _, status = Open3.capture2("mv \
                                 #{REPO_ROOT}/#{INSTALL_DIR}/nats-server-*/nats-server \
                                 #{REPO_ROOT}/#{INSTALL_DIR}/#{EXECUTABLE_NAME}")
      raise 'error moving nats binary' unless status.success?
    end

    def self.executable_path
      "#{REPO_ROOT}/#{INSTALL_DIR}/#{EXECUTABLE_NAME}"
    end
  end
end
