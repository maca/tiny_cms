require 'helper'

class PagesControllerTest < ActionController::TestCase
  should_route :get,  '/pages',                  :controller => :pages, :action => :index
  should_route :post, '/pages',                  :controller => :pages, :action => :create
  should_route :put,  '/pages/1',                :controller => :pages, :action => :update, :id   => '1'
  should_route :put,  '/pages/reorder',          :controller => :pages, :action => :reorder
  should_route :get,  '/pages/1/edit',           :controller => :pages, :action => :edit,   :id   => '1'
  should_route :get,  '/pages/1',                :controller => :pages, :action => :show,   :id   => '1'
  should_route :get,  '/root/children/children', :controller => :pages, :action => :show,   :path => %w(root children children)

  context 'get index' do
    context "as html" do
      setup { get :index }
      should_respond_with :success
      should_render_with_layout
      should_not_assign_to :pages
      # should_render_template 'pages/index'
    end

    context "as json" do
      setup do
        Page.destroy_all
        Factory :page, :children => [Factory(:page)], :is_page => false
        get :index, :format => 'json'
      end

      should_respond_with :success
      should_render_without_layout
      should "respond with page roots as json" do
        assert_equal Page.roots.to_json, @response.body
      end
    end
  end

  context 'get show' do
    setup do
      Page.destroy_all
      @page = Factory :page
    end

    context 'with id' do
      setup { get :show, :id => @page.id }
      should_respond_with :success
      should_render_with_layout
      should_assign_to(:page){ @page }
      # should_render_template 'pages/show'
    end

    context 'with path' do
      setup { get :show, :path => @page.path.scan(/\w+/) }
      should_respond_with :success
      should_render_with_layout
      should_assign_to(:page){ @page }
      # should_render_template 'pages/show'
    end

    should 'raise active record not found when node is not a page' do
      @page.update_attribute :is_page, false
      assert_raises ActiveRecord::RecordNotFound do
        get :show, :path => @page.path.scan(/\w+/)
      end
    end

    should 'raise active record not found with non existant path' do
      assert_raises ActiveRecord::RecordNotFound do
        get :show, :path => %w(not_existing_path)
      end
    end
  end

  context 'post create' do
    context 'with json' do
      context 'with valid attributes' do
        setup do
          post :create, :format => 'json', :page => Factory.attributes_for(:page)
        end
        should_change(:by => 1){ Page.count }
        should_respond_with :created
        should_render_without_layout
        should_assign_to :page
        should "respond with json representation" do
          assert_equal assigns(:page).to_json, @response.body
        end
      end

      context 'with invalid attributes' do
        setup do
          post :create, :format => 'json', :page => {:title => nil, :parent_id => nil}
        end
        should_not_change(:by => 1){ Page.count }
        should_respond_with :unprocessable_entity
        should_render_without_layout
        should_assign_to :page
        should "respond with json representation" do
          assert_equal assigns(:page).errors.to_json, @response.body
        end
      end
    end
  end

  context 'get edit' do
    context 'as html' do
      setup do
        @page = Factory :page
        get :edit, :id => @page.id
      end
      should_respond_with :success
      should_render_with_layout
      should_assign_to(:page){ @page }
      # should_render_template 'pages/index'
    end

  end

  context 'put update' do
    context 'full update' do
      context 'with html' do
        context 'with valid params' do
          setup do
            @page = Factory :page
            put :update, :page => {:title => 'Changed title'}, :id => @page.id
          end
          should_redirect_to('page path'){ page_path(@page) }
          should "change title" do
            assert_equal 'Changed title', @page.reload.title
          end
        end

        context 'with invalid params' do
          setup do
            @page = Factory :page
            put :update, :page => {:title => nil}, :id => @page.id
          end
          should_respond_with :success
          should_render_with_layout
          should_assign_to(:page){ @page }
          # should_render_template 'pages/index'
        end
      end

      context 'with json' do
        context 'with valid params' do
          setup do
            @page              = Factory :page
            put :update, :page => {:title => 'Changed title'}, :id => @page.id, :format => 'json'
          end
          should_respond_with :ok
          should_render_without_layout
          should_assign_to :page
        end

        context 'with invalid params' do
          setup do
            @page              = Factory :page
            put :update, :page => {:title => nil}, :id => @page.id, :format => 'json'
          end
          should_respond_with :unprocessable_entity
          should_render_without_layout
          should_assign_to :page
          should "respond with json representation" do
            assert_equal assigns(:page).errors.to_json, @response.body
          end
        end

      end
    end

    context 'reorder children' do
      setup do
        @page     = Factory :page
        @children = (0...5).map{ |i| Factory :page, :position => i }
        assert_equal (0...5).map, @children.map(&:position)
        put :update, :page => {:child_ids => @children.reverse.map(&:id)}, :id => @page.id
      end

      should 'assign a position to children when passed child_ids' do
        assert_equal (0...5).map, Page.find(:all, :conditions => ['id IN (?)', @children.map(&:id)]).reverse.map(&:position)
      end
    end
  end
  
  context 'put reorder' do
    context 'reorder children' do
      setup do
        @page     = Factory :page
        @children = (0...5).map{ |i| Factory :page, :position => i }
        assert_equal (0...5).map, @children.map(&:position)
        put :reorder, :page => {:child_ids => @children.reverse.map(&:id)}
      end
      
      should 'not be child of other node' do
        assert_equal (0...5).map{ nil }, Page.find(:all, :conditions => ['id IN (?)', @children.map(&:id)]).map(&:parent_id)
      end

      should 'assign a position to children when passed child_ids' do
        assert_equal (0...5).map, Page.find(:all, :conditions => ['id IN (?)', @children.map(&:id)]).reverse.map(&:position)
      end
    end
  end
  
  context 'delete destroy' do
    setup do
      @page = Factory :page
    end

    context 'with json' do
      context 'with valid attributes' do
        setup do
          delete :destroy, :id => @page.id, :format => 'json'
        end
        should_change(:by => -1){ Page.count }
        should_respond_with :ok
        should_render_without_layout
        should_assign_to :page
      end
    end

    context 'with html' do
      context 'with valid attributes' do
        setup do
          delete :destroy, :id => @page.id
        end
        should_change(:by => -1){ Page.count }
        should_redirect_to('pages'){ pages_path }
        should_render_without_layout
      end
    end
  end
end