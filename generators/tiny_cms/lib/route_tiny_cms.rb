module Rails
  module Generator
    module Commands
      class Create < Base

        # Create devise route. Based on route_resources
        def route_tiny_cms resource
          new_routes = "map.resources :#{resource}, :except => [:new], :collection => {:reorder => :put}\n  map.all '*path', :controller  => :#{resource}, :action => :show"
          logger.route new_routes
          
          unless options[:pretend]
            gsub_file 'config/routes.rb', /(end(?:\n|\s)*\Z)/mi do |match|
              "  #{ new_routes }\nend"
            end
          end
        end
      end

      class Destroy < RewindBase
        # Destroy devise route. Based on route_resources
        def route_tiny_cms resource
          logger.route "Removing routes for #{resource} resource and catch all route"
          
          new_routes = "  map.resources :#{resource}, :except => [:new], :collection => {:reorder => :put}\n  map.all '*path', :controller  => :#{resource}, :action => :show\n"
          gsub_file 'config/routes.rb', new_routes, ''
        end
      end
    end
  end
end