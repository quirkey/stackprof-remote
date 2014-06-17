require 'helper'

class TestStackProfRemote < MiniTest::Unit::TestCase

  def test_should_load_a_marshaled_dump
    report = StackProf::Remote::ProcessReportCollector.report_from_marshaled_results(File.read('./test/test.dump'))
    assert report
    assert_kind_of StackProf::Report, report
  end

  def test_should_print_text
    report = StackProf::Remote::ProcessReportCollector.report_from_marshaled_results(File.read('./test/test.dump'))
    str = StringIO.new
    assert report.print_text(false, 10, str)
    assert_match(/ActiveSupport/, str.string)
  end

end
