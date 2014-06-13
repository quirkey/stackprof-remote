require 'fileutils'
require 'stackprof'

module StackProf
  module Remote
    class Middleware
      class << self
        attr_accessor :enabled, :mode, :interval, :path, :logger

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

        Middleware.path     = options[:path] || 'tmp'
        Middleware.logger   = options[:logger] || Logger.new(STDOUT)
        logger.info "[stackprof] Stackprof Middleware enabled"
      end

      def call(env)
        path = env['PATH_INFO']
        if in_stackprof?(path)
          handle_stackprof(path)
        else
          @app.call(env)
        end
      end

      private
      def logger
        StackProf::Remote.logger
      end

      def in_stackprof?(path)
        path =~ /^\/__stackprof__/
      end

      def handle_stackprof(path)
        sp = StackProf::ProcessReportCollector.new(:path => Middleware.path)
        if path =~ /start/
          # Stackprof start
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
          path     = File.expand_path(File.join(base_path, filename))
          File.open(path, 'wb') do |f|
            f.write results
          end
          path
        end
      end
    end
  end
end
