module TinyCMS
  class PagesController < ApplicationController
    helper_method :resource
    
    def index
      respond_to do |format|
        format.html {
          @class = klass
          render 'tiny_cms/index' 
        }
        format.json { render :json => klass.include_tree(5).roots }
      end
    end

    def show
      if params[:id]
        set_resource klass.find(params[:id]) 
      else
        set_resource klass.by_path(params[:path]).first
        raise ActiveRecord::RecordNotFound if resource.nil? or resource.content.blank?
      end
      render 'tiny_cms/show'
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
      render 'tiny_cms/edit'
    end
    
    def update
      set_resource klass.find(params[:id])
      respond_to do |format|
        if resource.update_attributes params[resource_name]
          format.html { redirect_to resource }
          format.json { render :json => {} }
        else
          format.html { render 'tiny_cms/edit' }
          format.json { render :json => resource.errors, :status => :unprocessable_entity }
        end
      end
    end
    
    def reorder
      if klass.reorder params[:page]['child_ids']
        render :json => {}
      else
        render :json => {}, :status => :unprocessable_entity
      end
    end
    
    def destroy
      set_resource klass.find(params[:id])
      resource.destroy
      
      respond_to do |format|
        format.html { redirect_to :controller => params[:controller], :action => 'index'}
        format.json { render :json => {} }
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