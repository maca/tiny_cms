require 'rubygems'

$LOAD_PATH.unshift "#{ File.dirname __FILE__ }/../lib"
$LOAD_PATH.unshift File.dirname(__FILE__)

require 'rails_app/config/environment'

require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'factory_girl'
require 'support/page_migration'

class Test::Unit::TestCase
  # Hack to be able to do route testing
  def clean_backtrace(&block)
    yield
  rescue ActiveSupport::TestCase::Assertion => error
    framework_path = Regexp.new(File.expand_path("#{File.dirname(__FILE__)}/assertions"))
    error.backtrace.reject! { |line| File.expand_path(line) =~ framework_path }
    raise
  end
end

Factory.define :page do |p|
  p.sequence(:title) { |i| "Node #{i}"}
  p.sequence(:permalink) { |i| "node_#{i}"}
end
