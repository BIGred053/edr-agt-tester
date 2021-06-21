require_relative 'logger/logfile'
require_relative 'logger/process_logger'
require_relative 'logger/network_activity_decorator'
require 'net/http'
require 'socket'
require 'uri'

module EDRTest
  class NetworkActivity
    DEFAULT_URL = 'https://ptsv2.com/t/4c7w5-1624299313/post'
    DEFAULT_DATA = '{ "foo": "bar", "foo1": "bar1", "foo2": "bar2" }'

    def initialize(logfile: nil)
      @logfile = logfile || EDRTest::Logger::Logfile.new
      @logger = EDRTest::Logger::NetworkActivityDecorator.new(EDRTest::Logger::ProcessLogger.new)
    end

    attr_reader :logger, :logfile

    def send_data(url=DEFAULT_URL, data=DEFAULT_DATA)
      uri = URI(url)
      url_ip = IPSocket::getaddress(uri.host)
      source_ip = IPSocket.getaddress(Socket.gethostname)
      source_info = {}
      dest_info = {}
      bytes_sent = nil
      tx_protocol = nil

      conn = Net::HTTP.new(url_ip)
      conn.start do |c|
        c.post(uri.path, data)

        if OS.mac?
          net_stats = `netstat -nlb | grep #{url_ip}`

          return if net_stats.empty?
          puts net_stats
          net_info = net_stats.split(/\s+/)

          source_info = ip_and_port(net_info[3])
          dest_info = ip_and_port(net_info[4])
          bytes_sent = "#{net_info[-1]} bytes"
          tx_protocol = net_info[0]
        elsif OS.linux?
          net_stats = `netstat -nlt | grep #{url_ip}`

          return if net_stats.empty?
          puts net_stats

          # source_info = ip_and_port(net_info[3])
          # dest_info = ip_and_port(net_info[4])

          # transfer_info = `sudo tcpdump -i eth0 -w /tmp/tcpdump.pcap host #{dest_info[:port]}`
        end
      end

      @logfile.write(@logger.build_log(dest_info, source_info, bytes_sent, tx_protocol, Process.pid))
    end

    def public_send_data
      puts "Performing test network request..."
      send_data
      puts "Network test complete!"
    end

    private

    def ip_and_port(addr)
      last_dot_idx = addr.rindex('.')

      ip = addr[0...last_dot_idx]
      port = addr[last_dot_idx+1..-1]

      { addr: ip, port: port }
    end
  end

  module OS
    def OS.windows?
      (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
    end
  
    def OS.mac?
     (/darwin/ =~ RUBY_PLATFORM) != nil
    end
  
    def OS.unix?
      !OS.windows?
    end
  
    def OS.linux?
      OS.unix? and not OS.mac?
    end
  end
end
