require_relative 'logger/logfile'
require_relative 'logger/process_logger'
require 'open3'

module EDRTest
  class ProcessRunner
    DEFAULT_COMMAND = 'man git'
    def initialize(logfile: nil)
      @logfile = logfile || EDRTest::Logger::Logfile.new
      @logger = EDRTest::Logger::ProcessLogger.new
    end

    attr_accessor :logger, :logfile

    def run_process(command=DEFAULT_COMMAND)
      pid = Process.spawn(command)
      @logfile.write(@logger.build_log(pid))
      Process.detach(pid)
    end
  end
end

pr = EDRTest::ProcessRunner.new
pr.logfile.start_log

pr.run_process

pr.logfile.stop_log
