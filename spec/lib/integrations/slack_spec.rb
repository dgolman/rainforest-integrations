require 'spec_helper'
require 'integrations'

describe Integrations::Slack do
  describe '#initialize' do
    let(:event_name) { 'run_failure' }
    let(:payload) do
      {
        run: {
          id: 3,
          status: 'failed'
        }
      }
    end
    let(:settings) { { url: 'https://slack.com/bogus_integration' } }

    subject { described_class.new(event_name, payload, settings) }

    context 'without a valid integration url' do
      let(:settings) { {} }

      it 'raises a MisconfiguredIntegrationError' do
        expect { subject }.to raise_error Integrations::MisconfiguredIntegrationError
      end
    end
  end

  describe "send to Slack" do
    context "notify of run_completion" do
      let(:event_name) { "run_completion" }
      let(:payload) { {:id => 0} }
      let(:settings) { {:url => "https://hooks.slack.com/services/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"} }

      it 'sends a message to Slack' do
        VCR.use_cassette('run_completion_notify_slack') do
          Integrations::Slack.new(event_name, payload, settings).send_event
        end
      end
    end

    context "notify of run_error" do
      let(:event_name) { "run_error" }
      let(:payload) { {:id => 0} }
      let(:settings) { {:url => "https://hooks.slack.com/services/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"} }

      it 'sends a message to Slack' do
        VCR.use_cassette('run_error_notify_slack') do
          Integrations::Slack.new(event_name, payload, settings).send_event
        end
      end
    end

    context "notify of run_webhook_timeout" do
      let(:event_name) { "run_webhook_timeout" }
      let(:payload) { {:id => 0} }
      let(:settings) { {:url => "https://hooks.slack.com/services/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"} }

      it 'sends a message to Slack' do
        VCR.use_cassette('run_webhook_timeout_notify_slack') do
          Integrations::Slack.new(event_name, payload, settings).send_event
        end
      end
    end

    context "notify of run_test_failure" do
      let(:event_name) { "run_test_failure" }
      let(:payload) { {:id => 0} }
      let(:settings) { {:url => "https://hooks.slack.com/services/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"} }

      it 'sends a message to Slack' do
        VCR.use_cassette('run_test_failure_notify_slack') do
          Integrations::Slack.new(event_name, payload, settings).send_event
        end
      end
    end

  end
end
