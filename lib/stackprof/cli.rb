require 'pry'
require_relative 'process_report_collector'

module StackProf
  class CLI

    class << self
      def set_defaults
        Pry.config.should_load_rc = false
        Pry.config.prompt = proc {
          "stackprof#{@current_report ? " (#{@current_report})" : ""}> "
        }
      end

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

      def start(file, options = {})
        set_defaults
        add_methods
        initial = file ? StringIO.new("load-dump #{file}") : nil
        Pry.start(nil, :input => initial)
      end
    end

    class Session
      attr_reader :ctx

      def load_dump(file)
        data = File.read(file)
        @report = StackProf::ProcessReportCollector.report_from_marshaled_results(data)
        @current_report = File.basename(file)
        puts ">>> #{@current_report} loaded"
      end

      def top(limit = 10)
        check_for_report
        @report.print_text(false, limit.to_i, ctx.output)
      end

      def total(limit = 10)
        check_for_report
        @report.print_text(true, limit.to_i, ctx.output)
      end

      def all
        check_for_report
        page do |out|
          @report.print_text(false, nil, out)
        end
      end

      def print_method(method)
        check_for_report
        page do |out|
          @report.print_method(method, out)
        end
      end

      def check_for_report
        if !@report
          output.puts "You have to load a dump first with load-dump"
          return
        end
      end

      def with_context(ctx, &block)
        @ctx = ctx
        res = yield self
        @ctx = nil
        res
      end

      def puts(*args)
        ctx.output.puts(*args)
      end

      def page(&block)
        out = StringIO.new
        yield out
        ctx._pry_.pager.page out.string
      end

    end
  end
end
