ActionController::Routing::Routes.draw do |map|
  
  map.resources :pages, :except => [:new]
  map.all '*path', :controller => :pages, :action => :show
  
end
