require_relative 'base_logger'

module EDRTest
  module Logger
    class LoggerDecorator < BaseLogger
      attr_accessor :logger
      def initialize(logger)
        @logger = logger
      end

      def build_log(**args)
        @logger.build_log(**args)
      end
    end
  end
end