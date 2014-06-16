require 'net/http'
require 'fileutils'
require 'stackprof/cli'

module StackProf
  module Remote
    # Client wraps the script that uses net/http to make the start/stop
    # requests to a host running the StackProf::Remote::Middleware
    class Client
      attr_reader :host

      def initialize(host, wait)
        @host = host
        @wait = (wait || 30).to_i
        check_host
      end

      def run
        start
        wait
        fetch_results
        save_results
        enter_console
      end

      def start
        puts "=== StackProf on #{host} ==="
        puts "Starting"
        result = Net::HTTP.get(host, "/__stackprof__/start")
        puts "[#{host}] #{result}"
        if result !~ /Started/
          raise "Did not start successfully"
        end
      end

      def wait
        puts "Waiting for #{@wait} seconds"
        sleep @wait
      end

      def fetch_results
        response = Net::HTTP.get_response(host, "/__stackprof__/stop")
        if response.code == 200
          @results = response.body
          if !@results
            raise "Could not retreive results"
          end
          puts "[#{host}] Results: #{@results.bytesize / 1024}kb"
        else
          puts "[#{host}] Returned a #{response.code} response"
          puts response.body
          raise "Bad Response"
        end
      end

      def result_path
        result_dir = File.expand_path('~/.sp')
        FileUtils.mkdir_p(result_dir)
        @result_path ||= File.expand_path(File.join(result_dir, "sp-#{@host}-#{Time.now.to_i}.dump"))
      end

      def save_results
        File.open(result_path, 'wb') {|f| f << @results }
        puts "Saved results to #{result_path}"
      end

      def enter_console
        StackProf::CLI.start(result_path)
      end

      private
      def check_host
        if !host || !URI.parse(host)
          raise "Please supply a valid host to connect to (#{host})"
        end
      end
    end
  end
end
