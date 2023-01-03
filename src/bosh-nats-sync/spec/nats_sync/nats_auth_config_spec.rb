require 'spec_helper'
require 'nats_sync/nats_auth_config'

module NATSSync
  describe NatsAuthConfig do
    subject { NatsAuthConfig.new(vms, director_subject, hm_subject) }
    let(:vms) do
      [
        {
          'permanent_nats_credentials' => true,
          'agent_id' => 'fef068d8-bbdd-46ff-b4a5-bf0838f918d9',
        },
        {
          'permanent_nats_credentials' => true,
          'agent_id' => 'c5e7c705-459e-41c0-b640-db32d8dc6e71',
        },
      ]
    end
    let(:director_subject) { 'subject=C = USA, O = Cloud Foundry, CN = default.hm.bosh-internal' }
    let(:hm_subject) { 'C = USA, O = Cloud Foundry, CN = default.hm.bosh-internal' }

    describe '#execute_nats_auth_config' do
      describe 'read config' do
        it 'returns the vms belonging to the deployments' do
          created_config = subject.create_config
          expect(created_config['authorization']['users'].length).to eq(4)
          expect(created_config['authorization']['users'][0]['user']).to eq(director_subject)
          expect(created_config['authorization']['users'][1]['user']).to eq(hm_subject)
          expect(created_config['authorization']['users'][2]['user'])
            .to eq("C=USA, O=Cloud Foundry, CN=long-lived-#{vms[0]['agent_id']}.agent.bosh-internal")
        end
      end
      describe 'with no director or hm subjects' do
        let(:director_subject) { nil }
        let(:hm_subject) { nil }

        it 'returns the vms belonging to the deployments' do
          created_config = subject.create_config
          expect(created_config['authorization']['users'].length).to eq(2)
          expect(created_config['authorization']['users'][0]['user'])
            .to eq("C=USA, O=Cloud Foundry, CN=long-lived-#{vms[0]['agent_id']}.agent.bosh-internal")
        end
      end
      describe 'when the vms do not have permanent nats credentials' do
        let(:vms) do
          [
            {
              'permanent_nats_credentials' => true,
              'agent_id' => 'fef068d8-bbdd-46ff-b4a5-bf0838f918d9',
            },
            {
              'permanent_nats_credentials' => false,
              'agent_id' => 'c5e7c705-459e-41c0-b640-db32d8dc6e71',
            },
          ]
        end

        it 'returns the pair of long lived and short lived credentials belonging to the vms in the deployments' do
          created_config = subject.create_config
          expect(created_config['authorization']['users'].length).to eq(5)
          expect(created_config['authorization']['users'][0]['user']).to eq(director_subject)
          expect(created_config['authorization']['users'][1]['user']).to eq(hm_subject)
          expect(created_config['authorization']['users'][2]['user'])
            .to eq("C=USA, O=Cloud Foundry, CN=long-lived-#{vms[0]['agent_id']}.agent.bosh-internal")
          expect(created_config['authorization']['users'][3]['user'])
            .to eq("C=USA, O=Cloud Foundry, CN=#{vms[1]['agent_id']}.agent.bosh-internal")
          expect(created_config['authorization']['users'][4]['user'])
            .to eq("C=USA, O=Cloud Foundry, CN=long-lived-#{vms[1]['agent_id']}.agent.bosh-internal")
        end
      end
    end
  end
end
