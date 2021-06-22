require_relative 'logger/logfile'
require_relative 'logger/process_logger'
require_relative 'logger/network_activity_decorator'
require_relative 'os_finder'
require 'net/http'
require 'socket'
require 'uri'

module EDRTest
  class NetworkActivity
    DEFAULT_URL = 'https://ptsv2.com/t/4c7w5-1624299313/post'.freeze
    DEFAULT_DATA = '{ "foo": "bar", "foo1": "bar1", "foo2": "bar2" }'.freeze

    def initialize(logfile: nil, os: nil)
      @logfile = logfile || EDRTest::Logger::Logfile.new
      @logger = EDRTest::Logger::NetworkActivityDecorator.new(EDRTest::Logger::ProcessLogger.new)
      @curr_os = os
    end

    attr_reader :logger, :logfile

    def send_data(url=DEFAULT_URL, data=DEFAULT_DATA)
      uri = URI(url)
      url_ip = IPSocket::getaddress(uri.host)
      netstat_args = case @curr_os
                     when :mac
                       '-nlb'
                     when :linux
                       '-tunp'
                     end
      network_activity = {}

      conn = Net::HTTP.new(url_ip)
      conn.start do |c|
        c.post(uri.path, data) if OSFinder.mac?

        net_stats = `netstat #{netstat_args} | grep #{url_ip}`
        break if net_stats.empty?

        network_activity = extract_network_info(net_stats)

        if OSFinder.linux?
          `sudo iptables -A INPUT -p tcp --sport #{network_activity[:source][:port]}`

          c.post(uri.path, data)

          ip_info = `sudo iptables -n -L OUTPUT -v`
          network_activity[:data_sent] = ip_info[/\d+\sbytes/]
        end
      end

      log(network_activity) unless network_activity.empty?
    end

    def log(network_activity)
      @logfile.write(@logger.build_log(
                       network_activity[:dest],
                       network_activity[:source],
                       network_activity[:data_sent],
                       network_activity[:protocol],
                       Process.pid
                     ))
    end

    def run
      puts 'Performing test network request...'
      send_data
      puts 'Network test complete!'
    end

    private

    def extract_network_info(net_stats)
      net_info = net_stats.split(/\s+/)
      source_info = ip_and_port(net_info[3])
      dest_info = ip_and_port(net_info[4])
      tx_protocol = net_info[0]
      bytes_sent = "#{net_info[-1]} bytes" if OSFinder.mac?

      {source: source_info, dest: dest_info, protocol: tx_protocol, data_sent: bytes_sent}
    end

    def ip_and_port(addr)
      port_delimiter_idx = addr.rindex('.') if OSFinder.mac?
      port_delimiter_idx = addr.rindex(':') if OSFinder.linux?

      ip = addr[0...port_delimiter_idx]
      port = addr[port_delimiter_idx+1..]

      { addr: ip, port: port }
    end
  end
end
