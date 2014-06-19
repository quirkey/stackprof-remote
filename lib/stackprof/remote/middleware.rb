require 'fileutils'
require 'stackprof'
require 'stackprof/remote/process_report_collector'

module StackProf
  module Remote
    # Middleware is a simple Rack middleware that handles requests to
    # urls matching /__stackprof__ for starting/stopping a profile
    # session and retreiving the dump files. It delegates to the
    # ProcessReportCollector to do the actual work of collecting
    # and combining the dumps.
    class Middleware
      class << self
        attr_accessor :enabled, :logger, :options

        def enabled?(env)
          if enabled.respond_to?(:call)
            enabled.call(env)
          else
            enabled
          end
        end
      end

      def initialize(app, options = {})
        @app       = app
        self.class.logger   = options[:logger] || Logger.new(STDOUT)
        self.class.enabled  = options[:enabled] || false
        self.class.options  = options
        logger.info "[stackprof] Stackprof Middleware enabled"
      end

      def call(env)
        path = env['PATH_INFO']
        if self.class.enabled?(env) && in_stackprof?(path)
          handle_stackprof(path)
        else
          @app.call(env)
        end
      end

      private
      def logger
        self.class.logger
      end

      def in_stackprof?(path)
        path =~ /^\/__stackprof__/
      end

      def handle_stackprof(path)
        sp = StackProf::Remote::ProcessReportCollector.new(self.class.options)
        if path =~ /start/
          logger.debug "[stackprof] Starting StackProf"
          sp.start
          [200, {'Content-Type' => 'text/plain'}, ["StackProf Started"]]
        elsif path =~ /stop/
          logger.debug "[stackprof] Flushing StackProf"
          sp.stop
          sp.save
          if results = sp.marshaled_results
            [200, {'Content-Type' => 'binary/octet-stream'}, [results]]
          else
            [404, {'Content-Type' => 'text/plain'}, ["404 StackProf Results Not Found"]]
          end
        end
      end
    end

    module ReportSaver
      def self.marshaled_results
        if results = StackProf.results
          Marshal.dump(results)
        end
      end

      def self.save(base_path)
        if results = marshaled_results
          FileUtils.mkdir_p(base_path)
          filename = "stackprof-#{Process.pid}-#{Time.now.to_i}.dump"
          path     = File.join(base_path, filename)
          File.open(path, 'wb') do |f|
            f.write results
          end
          File.readable?(path) ? path : nil
        end
      end
    end
  end
end
