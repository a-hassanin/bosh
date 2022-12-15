module Bosh::Director
  module DeploymentPlan
    module Steps
      class PermanentNatsCredentialsStep

        WINDOWS_FIRST_SUPPORTED_VERSION = Bosh::Common::Version::StemcellVersion.parse('2019.41')
        XENIAL_FIRST_SUPPORTED_VERSION = Bosh::Common::Version::StemcellVersion.parse('621.171')
        BIONIC_FIRST_SUPPORTED_VERSION = Bosh::Common::Version::StemcellVersion.parse('1.36')

        def perform(report)

          return unless is_supported_version?(report.vm.stemcell_name, report.vm.stemcell_version)

          agent_permanent_creds = NatsClientCertGenerator.new(@logger).generate_nats_client_certificate "long-lived-#{report.vm.agent_id}.agent.bosh-internal"
          settings = {}
          settings['mbus'] = {
            'cert' => {
              'ca' => Config.nats_server_ca,
              'certificate' => agent_permanent_creds[:cert].to_pem,
              'private_key' => agent_permanent_creds[:key].to_pem,
            }
          }
          message_response = AgentClient.with_agent_id(report.vm.agent_id, report.vm.instance.name).update_settings(settings)
          Config.logger.info("Updating settings for #{report.vm.agent_id} with #{settings} response: #{message_response.inspect}")
          Config.logger.info("Updating settings for #{report.vm.agent_id} with #{settings} response: #{message_response}")
          Config.logger.info("VM permanent credentials boolean:  #{report.vm.inspect}")
          report.vm.update(permanent_nats_credentials: true)
        end

        private

        def is_supported_version?(stemcell_name, stemcell_version)
          stemcell_version = Bosh::Common::Version::StemcellVersion.parse(stemcell_version)

          case stemcell_name
          when /ubuntu-xenial/
            return stemcell_version >= XENIAL_FIRST_SUPPORTED_VERSION
          when /ubuntu-bionic/
            return stemcell_version >= BIONIC_FIRST_SUPPORTED_VERSION
          when /windows/
            return stemcell_version >= WINDOWS_FIRST_SUPPORTED_VERSION
          else
            return true
          end
        end
      end
    end
  end
end
