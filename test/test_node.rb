require 'helper'

class PageTest < Test::Unit::TestCase
  should_belong_to :parent
  should_have_many :children
  
  context 'attributes' do
    setup { @page = Factory :page, :rel => 'page' }
    should 'set is_page' do
      assert @page.is_page
    end
  end

  context 'children have positions' do
    setup do
      Page.destroy_all
      @root          = Factory :page
      @children      = (1..5).map{ Factory :page }
    end

    should 'have 5 children' do
      @root.children = @children
      assert_equal 5, @root.children.size
    end

    should 'assign a position to children' do
      @root.children = @children
      assert_equal (0...5).map, @root.children.map(&:position)
    end

    should 'assign a position to children when passed child_ids' do
      @root.child_ids = @children.map &:id
      assert_equal (0...5).map, @root.children.map(&:position)
    end

    context 'destroying root page' do
      setup do
        @root.children = @children
        @root.destroy
      end
      should_change(:from => 6, :to => 0){ Page.count }
    end
  end

  context 'order with children ids' do
    context 'all valid' do
      setup do
        Page.destroy_all
        @root           = Factory :page
        @children       = (1..5).map{ Factory :page }
        @root.update_attributes :child_ids => @children.map(&:id)
      end
    
      should 'have 5 children' do
        @root.children = @children
        assert_equal 5, @root.children.size
      end
    
      should 'assign a position to children when passed child_ids' do
        assert_equal (0...5).map, Page.find(:all, :conditions => ['id IN (?)', @root.children.map(&:id)]).map(&:position)
      end
    end
    
    context 'invalid children' do
      setup do
        Page.destroy_all
        @root  = Factory :page, :permalink => 'root',  :position  => 1, :is_page => false
        @root2 = Factory :page, :permalink => 'child', :position  => 2
        @child = Factory :page, :permalink => 'child',  :parent_id => @root.id,  :position => 1
        @root.child_ids = [@root2.id, @child.id]
        assert_equal false, @root.save
        @root.reload
        @root2.reload
        @child.reload
      end
      
      should 'not change order' do
        assert_equal 1, @root.position
        assert_equal nil, @root.parent_id
        
        assert_equal 2, @root2.position
        assert_equal nil, @root2.parent_id
        
        assert_equal 1, @child.position
        assert_equal @root.id, @child.parent_id
      end
    end
  end

  context 'scopes' do
    setup do
      Page.destroy_all
      @roots         = (1..5).map.reverse.map{ Factory :page }
      @children      = (1..5).map.reverse.map{ Factory :page }
      @roots.first.children = @children
      @roots.each{ |root| root.save and root.reload }
    end

    should 'getting siblings' do
      assert_equal @children[1..-1], @children.first.siblings
    end
    
    should 'getting siblings for root' do
      assert_equal [], @roots.first.siblings
    end

    should 'getting ordered root' do
      assert_equal @roots.map(&:id), Page.roots.map(&:id)
    end
  end

  context 'json generation' do
    setup do
      Page.destroy_all
      root   = Factory.build :page, :is_page => false
      @pages = (1..5).map{ |i| Factory.build :page, :is_page => i == 5 }

      @pages.inject(root){ |parent, child| parent.children.push(child) and child }
      @pages.unshift root
      @last          = @pages.last
      @first         = @pages.first
      @expected_path = "/#{@pages.map{ |p| p.permalink }.join('/')}" 
    end

    should 'override to json' do
      walk = lambda do |node|
        {:attributes => {'data-node-id' => node.id, :rel => node.is_page ? 'page' : 'section', 'data-path' => node.path, 'data-permalink' => node.permalink}, :data => node.title, :children => node.children.map{ |c| walk.call(c) }}
      end
      tree = walk.call @first
      assert_equal tree.to_json, @first.to_json
    end
  end
  
  context 'paths' do
    setup do
      Page.destroy_all
      root     = Factory :page, :is_page => false
      @branch1 = (1..4).map{ |i| Factory :page, :is_page => i == 3 }
      @branch1.inject(root){ |parent, child| parent.children.push(child) and child }
      @branch1.unshift root

      @branch2 = (1..4).map{ |i| Factory :page, :is_page => i == 3 }
      @branch2.inject(root){ |parent, child| parent.children.push(child) and child }
      @branch2.unshift root
    end
    
    should 'find by path including parents for one level for first branch' do
      path = [@branch1.first.permalink]
      assert_equal @branch1.first, Page.by_path(path).first
    end
    
    should 'find by path including parents for one level for second branch' do
      path = [@branch2.first.permalink]
      assert_equal @branch2.first, Page.by_path(path).first
    end
    
    should 'find by path including parents for two levels for first branch' do
      path = @branch1[0..1].map{ |p| p.permalink }
      assert_equal @branch1[1], Page.by_path(path).first
    end
    
    should 'find by path including parents for two levels for second branch' do
      path = @branch2[0..1].map{ |p| p.permalink }
      assert_equal @branch2[1], Page.by_path(path).first
    end
    
    should 'find by path including parents for three levels' do
      path = @branch1[0..2].map{ |p| p.permalink }
      assert_equal @branch1[2], Page.by_path(path).first
    end
    
    should 'find by path including parents for three levels for second branch' do
      path = @branch2[0..2].map{ |p| p.permalink }
      assert_equal @branch2[2], Page.by_path(path).first
    end
    
    should 'find by path including parents for four levels' do
      path = @branch1[0..3].map{ |p| p.permalink }
      assert_equal @branch1[3], Page.by_path(path).first
    end
    
    should 'find by path including parents for four levels for second branch' do
      path = @branch2[0..3].map{ |p| p.permalink }
      assert_equal @branch2[3], Page.by_path(path).first
    end
    
    should 'find by path including parents for five levels' do
      path = @branch1[0..4].map{ |p| p.permalink }
      assert_equal @branch1[4], Page.by_path(path).first
    end
    
    should 'find by path including parents for five levels for second branch' do
      path = @branch2[0..4].map{ |p| p.permalink }
      assert_equal @branch2[4], Page.by_path(path).first
    end

    should 'generate path' do
      assert_equal "/#{@branch1.map(&:permalink).join('/')}", @branch1.last.path
    end
  end

  context 'permalink parameterization' do
    setup do
      Page.destroy_all
    end

    should 'parameterize permalink' do
      @page = Factory :page, :permalink => '\This is teh pérmalink/'
      assert_equal 'this-is-teh-permalink', @page.permalink
    end

    should 'generate permalink from title' do
      @page = Factory :page, :title => 'This is teh title', :permalink => nil
      assert_equal 'this-is-teh-title', @page.permalink
    end

    # should 'convert to blank if permalink == index' do
    #   @page = Factory :page, :permalink => 'index'
    #   assert_equal '', @page.permalink
    # end
  end

  context 'validation' do
    should_validate_presence_of :title

    should 'not allow children if is page' do
      page = Factory.build :page, :is_page => true, :children => [Factory(:page)]
      assert_equal false, page.valid?
      assert_equal false, page.errors.on(:base).blank?
    end

    context 'permalink uniqueness' do
      setup do
        Page.destroy_all
        @page1 = Factory.build :page, :permalink => 'same'
        @page2 = Factory.build :page, :permalink => 'same'
        @page3 = Factory.build :page, :is_page   => false
        @page1.save(false)
        @page2.save(false)
        @page3.save(false)
      end

      should  'not allow duplicate if path is the same and both are pages' do
        assert_equal @page1.path,      @page2.path
        assert_equal @page1.permalink, @page2.permalink
        assert_equal false, @page2.valid?
        assert_equal false, @page2.errors.on(:permalink).blank?
      end

      # should 'allow duplicate if path is the same but one is not page' do
      #   @page1.update_attribute :is_page, false
      #   assert_equal @page1.path,      @page2.path
      #   assert_equal @page1.permalink, @page2.permalink
      #   @page1.save!
      #   assert_equal true, @page2.valid?
      # end

      should 'allow duplicate if paths are diferent and both are pages' do
        @page2.parent = @page3
        @page1.save(false)
        @page2.save(false)

        assert_not_equal @page1.path,       @page2.path
        assert_not_equal @page1.parent_id,  @page2.parent_id
        
        assert_equal @page1.permalink, @page2.permalink
        assert_equal true, @page2.valid?
      end

      # should 'validate presence of permalink if is not page' do
      #   page = Factory.build :page, :permalink => '', :is_page => false
      #   assert_equal false, page.valid?
      #   assert_equal false, page.errors.on(:permalink).blank?
      # end
    end
  end

  context 'Class reorder' do
    context 'success' do
      setup do
        @children = (0...5).map{ |i| Factory :page, :position => i }
      end
    
      should 'return true' do
        assert_equal true, Page.reorder(@children.map(&:id))
      end
      
      should 'reorder' do
        assert_equal true, Page.reorder(@children.reverse.map(&:id))
      end
    end
  end
end
