require_relative 'logger/logfile'
require_relative 'file_operations'
require_relative 'network_activity'
require_relative 'os_finder'
require_relative 'process_runner'

module EDRTest
  class Tester

    def initialize
      @logfile = EDRTest::Logger::Logfile.new
      @curr_os = OSFinder.set_os
    end

    def execute
      greet_user
      start_choice = welcome_prompt

      case start_choice
      when '1'
        perform_automated_run
      when '2'
        initiate_manual_run
      else
        puts 'Sorry, that seems to be an invalid input!'
      end
    end

    private

    def perform_automated_run
      @logfile.start_log
      EDRTest::ProcessRunner.new(logfile: @logfile).run_process # run and log default command

      EDRTest::NetworkActivity.new(logfile: @logfile, os: @curr_os).send_data

      fo = EDRTest::FileOperations.new(path: 'test', filetype: 'txt', logfile: @logfile)
      fo.create_file
      fo.modify_file(contents: 'Hello, World!')
      fo.delete_file

      @logfile.stop_log

      puts 'Automated run succesfully completed!'
    end

    def initiate_manual_run
      puts 'Which activity would you like to simulate? 1) Process 2) Network 3) File Ops X) Exit'
      user_answer = gets.chomp
      @logfile.start_log

      while user_answer.upcase != 'X'
        case user_answer
        when '1'
          EDRTest::ProcessRunner.new(logfile: @logfile).prompt_user
        when '2'
          EDRTest::NetworkActivity.new(logfile: @logfile, os: @curr_os).run
        when '3'
          EDRTest::FileOperations.new(path: 'test', filetype: 'txt', logfile: @logfile).prompt_user
        else
          puts 'Sorry, that seems to be an invalid input!'
        end

        puts 'Which activity would you like to simulate? 1) Process 2) Network 3) File Ops X) Exit'
        user_answer = gets.chomp
      end

      @logfile.stop_log
    end

    def greet_user
      puts 'Welcome! This is a utility to help regression test the EDR agent on this machine. It'\
        " operates by generating some various activity-\nfile operations, running commands, and"\
        " transferring data over the network.\nThese activities can be run manually one at a time,"\
        " or they can be run automatically using default values.\n\n"
    end

    def welcome_prompt
      puts 'Would you like to 1) Perform an automated test run or 2) Run tests manually?'
      gets.chomp
    end
  end
end

EDRTest::Tester.new.execute