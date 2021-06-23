require_relative '../edr_test/network_activity'
require 'rspec'

RSpec.describe EDRTest::NetworkActivity do
  subject { described_class.new(os: :mac) }
  let(:stubbed_conn) { instance_double(Net::HTTP) }
  let(:netstats) do
    'tcp4       0      0  192.168.86.250.59131   151.101.3.9.443        ESTABLISHED       1500       1370'
  end

  before do
    allow(Net::HTTP).to receive(:new).and_return(stubbed_conn)
    allow(stubbed_conn).to receive(:start).and_yield(stubbed_conn)
    allow(stubbed_conn).to receive(:post).and_return(nil)
    allow(subject).to receive(:`).and_return(netstats)
  end

  describe '.new' do
    context 'when a logfile is provided at initialization' do
      subject { described_class.new(logfile: predefined_logfile) }
      let(:predefined_logfile) { EDRTest::Logger::Logfile.new }

      it 'uses that logfile' do
        subject
        expect(subject.logfile).to eq predefined_logfile
      end
    end

    context 'when a logfile is not provided at initailization' do
      before { allow(EDRTest::Logger::Logfile).to receive(:new) }

      it 'generates a new logfile' do
        subject
        expect(EDRTest::Logger::Logfile).to have_received(:new)
      end
    end
  end

  describe '#send_data' do
    let(:expected_network_activity) do
      {
        source: { addr: '192.168.86.250', port: '59131' },
        dest: { addr: '151.101.3.9', port: '443' },
        data_sent: '1370 bytes',
        protocol: 'tcp4'
      }
    end

    it 'performs an HTTP POST request' do
      subject.send_data
      expect(stubbed_conn).to have_received(:post)
    end

    it 'records network activity data' do
      allow(subject).to receive(:log)
      subject.send_data
      expect(subject).to have_received(:log).with(expected_network_activity)
    end
  end
end