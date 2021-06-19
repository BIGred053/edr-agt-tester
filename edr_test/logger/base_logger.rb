module EDRTest
  module Logger
    class BaseLogger
      def build_log(pid)
        rails NotImplementedError, "#{self.class} has not implemented the #{__method__} method"
      end
    end
  end
end