ActionController::Routing::Routes.draw do |map|
  
  map.resources :pages, :except => [:new], :collection => {:reorder => :put}
  map.all '*path', :controller  => :pages, :action => :show
  
end
