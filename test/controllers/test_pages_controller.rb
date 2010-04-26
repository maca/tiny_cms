require 'helper'

class PagesControllerTest < ActionController::TestCase
  should_route :get, '/pages', :controller => :pages, :action => :index
  
  
  
  
end
