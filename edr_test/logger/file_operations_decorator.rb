require_relative 'logger_decorator'

module EDRTest
  module Logger
    class FileOperationsDecorator < LoggerDecorator
      def initialize(logger)
        @logger = logger
      end

      def build_log(filepath, file_activity, pid)
        {
          file_path: File.expand_path(filepath),
          file_activity: file_activity
        }.merge!(@logger.build_log(pid))
      end
    end
  end
end