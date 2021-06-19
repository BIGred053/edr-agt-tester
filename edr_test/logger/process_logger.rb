require_relative 'base_logger'
require 'json'
require 'time'

module EDRTest
  module Logger
    # This is a base class that covers all shared logging functionality required for each type of
    # activity covered within this test utility- File Operations, Process Creation, and Network
    # Traffic.
    class ProcessLogger < BaseLogger
      # #log(): Takes in a PID and generates log information associated with that PID, including
      # * Timestamp for process start time
      # * Username that started the process
      # * PID
      # * Process Name (e.g. `git`)
      # * Process Command Line (e.g `git commit -m "test message"`)
      def build_log(pid)
        return {} if `ps #{pid}`.split("\n").length == 1 # Short circuit if process not active

        log_info_flags = {
          start_time: 'lstart', username: 'user', proc_name: 'comm', proc_command_line: 'command'
        }
        log_hash = { pid: pid }

        log_info_flags.each do |info_type, flag|
          log_hash.merge!(fetch_process_info(info_type, flag, pid))
        end

        log_hash
      end

      private

      def fetch_process_info(info_type, flag, pid)
        curr_info = `ps -o #{flag} #{pid}`
        process_info = curr_info.split("\n")[1] # Remove the header provided by `ps`

        process_info = format_process_time(process_info) if info_type == :start_time
        { "#{info_type}": process_info }
      end

      def format_process_time(time)
        Time.parse(time).utc
      end
    end
  end
end
