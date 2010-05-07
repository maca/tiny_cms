require 'pages/node'
require 'pages/controller'
require 'pages/view_helpers'

module Pages
end

ActionView::Base.send(:include, Pages::ViewHelpers) 
