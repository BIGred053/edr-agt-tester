require_relative 'base_logger'

module EDRTest
  class FileOperations
    def initialize(path:, filetype:)
      @full_filename = path[-1] == '/' ? "#{path}test.#{filetype}" : "#{path}.#{filetype}"
      @logger = EDRTest::BaseLogger.new
    end

    attr_accessor :logger

    def create_file
      new_file = File.open(@full_filename, 'w')
      new_file.close
      @logger.build_log(Process.pid)
    end

    def modify_file(contents:)
      return unless File.exist? @full_filename

      File.open(@full_filename, 'w') do |modifyle|
        modifyle.write(contents)
      end
      @logger.build_log(Process.pid)
    end

    def delete_file
      File.delete(@full_filename) if File.exist? @full_filename
      @logger.build_log(Process.pid)
    end
  end
end

fo = EDRTest::FileOperations.new(path: 'sample', filetype: 'rb')
fo.logger.start_log

fo.create_file
fo.modify_file(contents: "puts 'hello, world!'")
fo.delete_file

fo.logger.stop_log
