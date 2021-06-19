module EDRTest
  module Logger
    class Logfile
      DEFAULT_LOGFILE = '../../logs/edr-test-log.json'.freeze
      def initialize(logfile = nil)
        @logfile = logfile || DEFAULT_LOGFILE
        @logfile = File.join(File.dirname(__FILE__), @logfile)
        @started = false
        @log_entries = 0
      end

      def write(log_hash)
        File.open(@logfile, 'a') do |logfile|
          log_to_write = "\"entry_#{@log_entries + 1}\": #{log_hash.to_json}"
          log_to_write = ", #{log_to_write}" unless @log_entries == 0
          logfile.write(log_to_write)
          @log_entries += 1
        end
      end

      def start_log
        File.open(@logfile, 'w') { |f| f.write('{') }
        @started = true
        @log_entries = 0
      end

      def stop_log
        File.open(@logfile, 'a') { |f| f.write('}') }
        @started = false
      end
    end
  end
end