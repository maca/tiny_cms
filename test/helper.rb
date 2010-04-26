$LOAD_PATH.unshift "#{ File.dirname __FILE__ }/../lib"
$LOAD_PATH.unshift File.dirname(__FILE__)

require 'rails_app/config/environment'

require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'factory_girl'

require 'support/page_migration'

Factory.define :page do |p|
  p.sequence(:title) { |i| "Node #{i}"}
  p.sequence(:permalink) { |i| "node_#{i}"}
end

class Test::Unit::TestCase
end
