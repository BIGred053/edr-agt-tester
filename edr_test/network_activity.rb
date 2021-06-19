require_relative 'logger/logfile'
require_relative 'logger/process_logger'
require 'net/http'
require 'socket'
require 'uri'

module EDRTest
  class NetworkActivity
    DEFAULT_URL = 'https://ptsv2.com/t/b76yt-1624085240/post'
    DEFAULT_DATA = '{ "foo": "bar" }'

    def initialize(logfile: nil)
      @logfile = logfile || EDRTest::Logger::Logfile.new
      @logger = EDRTest::Logger::ProcessLogger.new
    end

    attr_reader :logger, :logfile

    def send_data(url=DEFAULT_URL, data=DEFAULT_DATA)
      uri = URI(url)
      url_ip = IPSocket::getaddress(uri.host)
      source_ip = IPSocket.getaddress(Socket.gethostname)

      Net::HTTP.post(uri, data, 'Keep-Alive' => 'timeout=5, max=10')
      net_stats = `netstat -nlb | grep #{url_ip}`
      net_info = net_stats.split(/\s+/)

      source_details = ip_and_port(net_info[3])
      dest_details = ip_and_port(net_info[4])
      bytes_txed = net_info[-1]
      txfer_protocol = net_info[0]

      
      @logfile.write(@logger.build_log(Process.pid))
    end

    private

    def ip_and_port(addr)
      last_dot_idx = addr.rindex('.')
      port = addr[last_dot_idx+1..-1]
      ip = addr[0...last_dot_idx]
      [ip, port]
    end
  end
end

na = EDRTest::NetworkActivity.new
na.logfile.start_log

na.send_data

na.logfile.stop_log
