ActionController::Routing::Routes.draw do |map|
  map.dummy '/perma', :controller => 'dummy', :action => 'index'
  map.resources :pages, :except => [:new], :collection => {:reorder => :put}
  map.all '*path', :controller  => :pages, :action => :show
end
