require 'pry'
require 'stackprof/remote/process_report_collector'

module StackProf
  # CLI is a simple wrapper around Pry that defines some helper
  # methods for navigating stackprof dumps.
  class CLI

    class << self
      # Set prompts and other defaults
      def set_defaults
        Pry.config.should_load_rc = false
        Pry.config.prompt = proc {
          "stackprof#{@current_report ? " (#{@current_report})" : ""}> "
        }
      end

      # Add the helper methods to pry
      def add_methods
        session = Session.new
        Pry::Commands.block_command "load-dump", "Load a stackprof dump at file" do |file|
          session.with_context(self) {|s| s.load_dump(file) }
        end
        Pry::Commands.block_command "top", "print the top (n) results by sample time" do |limit|
          session.with_context(self) {|s| s.top(limit) }
        end
        Pry::Commands.block_command "total", "print the top (n) results by total sample time" do |limit|
          session.with_context(self) {|s| s.total(limit) }
        end
        Pry::Commands.block_command "all", "print all results by sample time" do
          session.with_context(self) {|s| s.all }
        end
        Pry::Commands.block_command "method", "scope results to matching matching methods" do |method|
          session.with_context(self) {|s| s.print_method(method) }
        end
      end

      # Start a Pry session with an optional file
      def start(file, options = {})
        set_defaults
        add_methods
        initial = file ? StringIO.new("load-dump #{file}") : nil
        Pry.start(nil, :input => initial)
      end
    end

    class Session
      attr_reader :ctx

      # Load a dump into a StackProf::Report object.
      def load_dump(file)
        data = File.read(file)
        @report = StackProf::Remote::ProcessReportCollector.report_from_marshaled_results(data)
        @current_report = File.basename(file)
        puts ">>> #{@current_report} loaded"
      end

      # Print the top `limit` methods by sample time
      def top(limit = 10)
        check_for_report
        @report.print_text(false, limit.to_i, ctx.output)
      end

      # Print the top `limit` methods by total time
      def total(limit = 10)
        check_for_report
        @report.print_text(true, limit.to_i, ctx.output)
      end

      # Print all the methods by sample time. Paged.
      def all
        check_for_report
        page do |out|
          @report.print_text(false, nil, out)
        end
      end

      # Print callers/callees of methods matching method. Paged.
      def print_method(method)
        check_for_report
        page do |out|
          @report.print_method(method, out)
        end
      end

      # Simple check to see if a report has been loaded.
      def check_for_report
        if !@report
          puts "You have to load a dump first with load-dump"
          return
        end
      end

      # Wrap the execution of a method with a Pry context
      def with_context(ctx, &block)
        @ctx = ctx
        res = yield self
        @ctx = nil
        res
      end

      # Helper to delegate puts to the current context
      def puts(*args)
        ctx.output.puts(*args)
      end

      # Wrap the output in pry's pager (less)
      def page(&block)
        out = StringIO.new
        yield out
        ctx._pry_.pager.page out.string
      end

    end
  end
end
