require 'spec_helper'

module Bosh::Director
  module DeploymentPlan
    module Steps
      describe PermanentNatsCredentialsStep do
        subject(:step) { described_class.new }

        let(:instance) { Models::Instance.make }
        let!(:vm) { Models::Vm.make(instance: instance, cpi: 'vm-cpi') }
        let(:report) { Stages::Report.new.tap { |r| r.vm = vm } }
        let(:agent_client) { instance_double(AgentClient, update_settings: nil) }
        let(:cert_generator) { instance_double 'Bosh::Director::NatsClientCertGenerator' }
        let(:cert) { instance_double 'OpenSSL::X509::Certificate' }
        let(:private_key) { instance_double 'OpenSSL::PKey::RSA' }

        describe '#perform' do
          before do
            allow(private_key).to receive(:to_pem).and_return('pkey begin\npkey content\npkey end\n')
            allow(cert).to receive(:to_pem).and_return('certificate begin\ncertificate content\ncertificate end\n')
            allow(NatsClientCertGenerator).to receive(:new).and_return(cert_generator)
            allow(Config).to receive(:nats_server_ca).and_return('nats begin\nnats content\nnats end\n')
            allow(cert_generator).to receive(:generate_nats_client_certificate).and_return(
              cert: cert,
              key: private_key,
            )
            allow(AgentClient).to receive(:with_agent_id).and_return(agent_client)
            allow(vm).to receive(:update)
          end

          it 'should generate a new certificate key pair' do
            expect(cert_generator).to receive(:generate_nats_client_certificate)

            step.perform(report)
          end

          it 'should send the credentials through the NATs call update_settings' do
            expect(agent_client).to receive(:update_settings).with('mbus' => {
              'cert' => {
                'ca' => 'nats begin\nnats content\nnats end\n',
                'certificate' => 'certificate begin\ncertificate content\ncertificate end\n',
                'private_key' => 'pkey begin\npkey content\npkey end\n',
              },
            })

            step.perform(report)
          end

          it 'should set the permanent_nats_credentials flag to true' do
            expect(vm).to receive(:update).with(permanent_nats_credentials: true)

            step.perform(report)
          end
        end
      end
    end
  end
end
