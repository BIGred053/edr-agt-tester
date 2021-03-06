require_relative 'logger/logfile'
require_relative 'logger/process_logger'
require 'open3'

module EDRTest
  class ProcessRunner
    DEFAULT_COMMAND = 'ls -is'
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

    def prompt_user
      puts 'Welcome! This utility exists to test running various processes, such as running a'\
        " Ruby program, executing a git command, or checking out a man page!\n\n"\
        'Please enter the command you wish to run, along with any relevant arguments:'

      next_command = gets.chomp

      while next_command.downcase != 'exit'
        run_process(next_command)

        puts "Your command has been run and logged! If you would like to run another, you may\n"\
          ' enter the command, along with any relevant arguments, or type "exit" to quit: '
        next_command = gets.chomp

        puts next_command
      end
    end
  end
end
