require_relative 'logger/file_operations_decorator'
require_relative 'logger/logfile'
require_relative 'logger/process_logger'

module EDRTest
  class FileOperations
    def initialize(path:, filetype:, logfile: nil)
      @full_filename = path[-1] == '/' ? "#{path}test.#{filetype}" : "#{path}.#{filetype}"
      @logfile = logfile || EDRTest::Logger::Logfile.new
      @logger = EDRTest::Logger::FileOperationsDecorator.new(EDRTest::Logger::ProcessLogger.new)
    end

    attr_accessor :logger, :logfile, :full_filename

    def create_file
      new_file = File.open(@full_filename, 'w')
      new_file.close
      @logfile.write(@logger.build_log(@full_filename, 'Create File', Process.pid))
    end

    def modify_file(contents:)
      return unless File.exist? @full_filename

      File.open(@full_filename, 'w') do |modifyle|
        modifyle.write(contents)
      end
      @logfile.write(@logger.build_log(@full_filename, 'Modified File', Process.pid))
    end

    def delete_file
      return unless File.exist? @full_filename

      File.delete(@full_filename)
      @logfile.write(@logger.build_log(@full_filename, 'Deleted File', Process.pid))
    end

    def self.prompt_user
      welcome_user

      file_path, file_type = user_file_details
      my_file = new(path: file_path, filetype: file_type)
      my_file.logfile.start_log

      puts 'Thank you! Which operation do you wish to perform?'
      puts '1) Create 2) Modify 3) Delete X) Exit'
      next_operation = gets.chomp

      while next_operation.upcase != 'X'
        case next_operation
        when '1'
          my_file.create_file
        when '2'
          puts 'Please enter the content you wish to write into the file and hit Enter'
          contents = gets.chomp
          my_file.modify_file(contents: contents)
        when '3'
          my_file.delete_file
        when '4'
          path, filetype = user_file_details
          my_file.full_filename = path[-1] == '/' ? "#{path}test.#{file_type}" : "#{path}.#{filetype}"
        else
          puts 'Sorry, that seems to be an invalid input!'
        end

        puts 'Thank you! Which operation do you wish to perform?'
        puts '1) Create 2) Modify 3) Delete 4) Set a new file X) Exit'
        next_operation = gets.chomp
      end

      my_file.logfile.stop_log
    end

    private

    class << self
      def welcome_user
        puts <<-MSG
          Welcome to the file operations simulator! Using this utility, you can input a file type
          and a file name or path (including filename) and perform the following operations with
          that file:

          1) Create the file (if it doesn't already exist)
          2) Provide contents to write to the file (does nothing if the file does not exist)
          3) Delete the file (does nothing if the file does not exist)\n
        MSG
      end

      def user_file_details
        puts <<-TYPE
          What type of file would you like to create? (Enter the file extension without the '.'- e.g. 
          `rb`, instead of `.rb`):
        TYPE
        file_type = gets.chomp

        puts 'What is the filename or path + filename you wish to create?'
        file_path = gets.chomp

        [file_path, file_type]
      end
    end
  end
end

EDRTest::FileOperations.prompt_user
