require 'rails_helper'
require 'integrations/formatter'

describe Integrations::Formatter do
  let(:class_instance) do
    klass = Class.new do
      include Integrations::Formatter
      attr_reader :run
    end
    klass.new
  end

  describe '#run_error_message' do
    context 'with a missing error reason' do
      context 'nil reason' do
        before do
          class_instance.instance_variable_set(:@run, { error_reason: nil })
        end

        it 'uses "unknown reason"' do
          expect(class_instance.run_error_message).to eq "errored: unspecified reason (please contact help@rainforestqa.com if you'd like help debugging this)."
        end
      end

      context 'empty string for a reason' do
        before do
          class_instance.instance_variable_set(:@run, { error_reason: "" })
        end

        it 'uses "unknown reason"' do
          expect(class_instance.run_error_message).to eq "errored: unspecified reason (please contact help@rainforestqa.com if you'd like help debugging this)."
        end
      end
    end
  end
end
