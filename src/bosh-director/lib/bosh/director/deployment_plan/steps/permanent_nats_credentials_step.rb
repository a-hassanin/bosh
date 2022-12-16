module Bosh::Director
  module DeploymentPlan
    module Steps
      class PermanentNatsCredentialsStep
        def perform(report)
          agent_permanent_creds = NatsClientCertGenerator.new(@logger).generate_nats_client_certificate "long-lived-#{report.vm.agent_id}.agent.bosh-internal"
          settings = {}
          settings['mbus'] = {
            'cert' => {
              'ca' => Config.nats_server_ca,
              'certificate' => agent_permanent_creds[:cert].to_pem,
              'private_key' => agent_permanent_creds[:key].to_pem,
            },
          }
          message_response = AgentClient.with_agent_id(report.vm.agent_id, report.vm.instance.name).update_settings(settings)
          Config.logger.info("Updating settings for #{report.vm.agent_id} with #{settings} response: #{message_response.inspect}")
          Config.logger.info("Updating settings for #{report.vm.agent_id} with #{settings} response: #{message_response}")
          Config.logger.info("VM permanent credentials boolean:  #{report.vm.inspect}")
          report.vm.update(permanent_nats_credentials: true)
        end
      end
    end
  end
end
