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
        if OS.mac?
          c.post(uri.path, data)
          net_stats = `netstat -nlb | grep #{url_ip}`

          return if net_stats.empty?
          net_info = net_stats.split(/\s+/)

          source_info = ip_and_port(net_info[3])
          dest_info = ip_and_port(net_info[4])
          bytes_sent = "#{net_info[-1]} bytes"
          tx_protocol = net_info[0]
        elsif OS.linux?
          net_stats = `netstat -tunpe --extend | grep #{url_ip}`

          return if net_stats.empty?
          puts net_stats
          net_info = net_stats.split(/\s+/)
          source_info = ip_and_port(net_info[3])
          dest_info = ip_and_port(net_info[4])
          `sudo iptables -A INPUT -p tcp --sport #{source_info[:port]}`
          c.post(uri.path, data)
          ip_info = `sudo iptables -n -L OUTPUT -v`
          bytes_sent = ip_info[/\d+\sbytes/]
          puts bytes_sent
          tx_protocol = net_info[0]
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
      port_delimiter_idx = addr.rindex('.') if OS.mac?
      port_delimiter_idx = addr.rindex(':') if OS.linux?

      ip = addr[0...port_delimiter_idx]
      port = addr[port_delimiter_idx+1..-1]

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
