module Pages
  module Controller
    def index
      klass.find :all
    end
    
    private
    def klass
      ActiveRecord.const_get params[:controller].classify
    end
    
    def set_resource value
      instance_variable_set "@#{ resource_name }"
    end
    
  end
end