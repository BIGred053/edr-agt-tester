require_relative 'logger_decorator'

module EDRTest
  module Logger
    class NetworkActivityDecorator < LoggerDecorator
      def initialize(logger)
        @logger = logger
      end

      def build_log(destination_info, source_info, bytes_sent, tx_protocol, pid)
        {
          destination_address: destination_info[:addr],
          destination_port: destination_info[:port],
          source_address: source_info[:addr],
          source_port: source_info[:port],
          amt_data_sent: bytes_sent,
          transfor_protocol: tx_protocol
        }.merge!(@logger.build_log(pid))
      end
    end
  end
end