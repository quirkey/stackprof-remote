require 'stackprof/report'
require 'rbtrace/rbtracer'

module StackProf
  module Remote
    # ProcessReportCollector handles the work of actually starting,
    # stopping, and collecting the dumps from the StackProf profiler.
    #
    # Internally it uses RBTrace to execute the start/stop methods
    # against all runnign processes that match pids found by the :pid_finder
    # option. By default this matches unicorn workers.
    class ProcessReportCollector
      DEFAULT_OPTIONS = {
        :pid_finder => -> {
          `pgrep -f 'unicorn worker'`.strip.split.collect {|p| p.to_i }
        },
        :mode => :cpu,
        :interval => 1000,
        :raw => true,
        :path => 'tmp'
      }.freeze

      def initialize(options = {})
        @options = DEFAULT_OPTIONS.merge(options)
        collect_pids
      end

      def logger
        StackProf::Remote::Middleware.logger
      end

      def start
        command = "StackProf.start(mode: #{@options[:mode].inspect}, interval: #{@options[:interval].inspect}, raw: #{@options[:raw].inspect})"
        execute(command)
      end

      def stop
        command = "StackProf.stop"
        execute(command)
      end

      def save
        command = "StackProf::Remote::ReportSaver.save('#{@options[:path]}')"
        @saved_files = execute(command)
      end

      def marshaled_results
        if @saved_files
          saved_data = @saved_files.collect {|f|
            Marshal.load(File.read(f))
          }
          Marshal.dump(saved_data)
        end
      end

      def self.report_from_marshaled_results(marshaled_data)
        data = Marshal.load(marshaled_data)
        report = data.inject(nil) {|sum, d| sum ? StackProf::Report.new(d) + sum : StackProf::Report.new(d) }
      end

      private
      def collect_pids
        logger.debug "[stackprof] Collecting PIDs"
        @pids = @options[:pid_finder].call
        @pids -= [Process.pid]
        logger.debug "[stackprof] Found PIDs #{@pids.inspect} and current #{Process.pid}"
      end

      def execute(command)
        logger.debug "[stackprof] execute: #{command}"
        results = @pids.collect do |pid|
          begin
            tracer = RBTracer.new(pid)
            output = tracer.eval(command)
          ensure
            tracer.detach if tracer
            output
          end
        end
        results << eval(command)
        logger.debug "[stackprof] Results: #{results.inspect}"
        results
      end
    end
  end
end
