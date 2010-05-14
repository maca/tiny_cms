module Pages
  module Controller
    def self.included controller
      controller.helper_method :resource
    end
    
    def index
      respond_to do |format|
        format.html { render 'pages/index' }
        format.json { render :json => klass.include_tree(5).roots }
      end
    end

    def show
      set_resource params[:path] ? klass.pages.by_path(params[:path]).first : klass.find(params[:id])
      raise ActiveRecord::RecordNotFound if resource.nil?
    end
    
    def create
      set_resource klass.new(params[resource_name])
      if resource.save
        render :json => resource, :status => :created
      else
        render :json => resource.errors, :status => :unprocessable_entity
      end
    end
    
    def edit
      @page = Page.find params[:id]
      render 'pages/edit'
    end
    
    def update
      set_resource klass.find(params[:id])
      respond_to do |format|
        if resource.update_attributes params[resource_name]
          format.html { redirect_to resource }
          format.json { head :ok }
        else
          format.html { render 'pages/edit' }
          format.json { render :json => resource.errors, :status => :unprocessable_entity }
        end
      end
    end
    
    def reorder
      klass.reorder(params[:page]['child_ids']) ? head(:ok) : head(:unprocessable_entity)
    end
    
    def destroy
      set_resource klass.find(params[:id])
      resource.destroy
      
      respond_to do |format|
        format.html { redirect_to :controller => params[:controller], :action => 'index'}
        format.json { head :ok }
      end
    end
    
    private
    def klass
      @klass ||= ActiveRecord.const_get params[:controller].classify
    end
    
    def resource_name
      params[:controller].singularize
    end
    
    def set_resource value
      instance_variable_set "@#{ resource_name }", value
    end

    def resource
      instance_variable_get "@#{ resource_name }"
    end
  end
end