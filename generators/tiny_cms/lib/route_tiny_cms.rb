module Rails
  module Generator
    module Commands
      class Create < Base

        # Create devise route. Based on route_resources
        def route_tiny_cms resource
          new_routes = <<-RUBY
            map.resources :#{resource}, :except => [:new], :collection => {:reorder => :put}
            map.all '*path', :controller  => :#{resource}, :action => :show
          RUBY
          
          logger.route new_routes
          
          unless options[:pretend]
            gsub_file 'config/routes.rb', /(end(?:\n|\s)*\Z)/mi do |match|
              <<-RUBY
                #{ new_routes }
              #{ match }
              RUBY
            end
          end
        end
      end

      class Destroy < RewindBase
        # Destroy devise route. Based on route_resources
        def route_devise resource
          logger.route "Removing routes for #{resource} resource and catch all route"

          look_for = "\n  map.resources :#{resource}, :except => [:new], :collection => {:reorder => :put}\n"
          gsub_file 'config/routes.rb', /(#{look_for})/mi, ''

          look_for = "\n  map.resources :#{resource}, :except => [:new], :collection => {:reorder => :put}\n"
          gsub_file 'config/routes.rb', /#{look_for}/mi, ''
        end
      end
    end
  end
end