require_relative 'logger/file_operations_decorator'
require_relative 'logger/logfile'
require_relative 'logger/process_logger'

module EDRTest
  class FileOperations
    def initialize(path:, filetype:)
      @full_filename = path[-1] == '/' ? "#{path}test.#{filetype}" : "#{path}.#{filetype}"
      @logfile = EDRTest::Logger::Logfile.new
      @logger = EDRTest::Logger::FileOperationsDecorator.new(EDRTest::Logger::ProcessLogger.new)
    end

    attr_accessor :logger, :logfile

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
      File.delete(@full_filename) if File.exist? @full_filename
      @logfile.write(@logger.build_log(@full_filename, 'Deleted File', Process.pid))
    end
  end
end

fo = EDRTest::FileOperations.new(path: 'sample', filetype: 'rb')
fo.logfile.start_log

fo.create_file
fo.modify_file(contents: "puts 'hello, world!'")
fo.delete_file

fo.logfile.stop_log
