module EDRTest
  module OSFinder
    def self.windows?
      (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
    end

    def self.mac?
     (/darwin/ =~ RUBY_PLATFORM) != nil
    end

    def self.unix?
      !windows?
    end

    def self.linux?
      unix? and !mac?
    end

    def self.set_os
      if windows?
        :windows
      elsif mac?
        :mac
      elsif linux?
        :linux
      else
        nil
      end
    end
  end
end
