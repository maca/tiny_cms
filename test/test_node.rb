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

  context 'nested attributes for children' do
    setup do
      Page.destroy_all
      @root                     = Factory :page, :is_page => false
      @children_attributes      = (1..5).map { Factory.attributes_for :page, :is_page => false }
      @root.children_attributes = @children_attributes
      @root.save!
    end

    should 'have 5 children' do
      assert_equal 5, @root.children.size
    end

    should 'assign a position to children' do
      assert_equal (0...5).map, @root.children.map(&:position)
    end

    should 'allow destroy' do
      @root.children_attributes = @root.children.map{ |ch| {'id' => ch.id, '_destroy' => true} }
      @root.save and @root.reload
      assert_equal 0, @root.children.size
    end

    should 'change positions using nested attributes' do
      attrs = @root.children.reverse.map{ |ch| {'id' => ch.id} }
      @root.children_attributes = attrs
      assert_equal  attrs.map{ |ch| {'id' => ch[:id], 'position' => ch[:position]} }, @root.children.sort_by(&:position).map{ |ch| {'id' => ch.id, 'position' => ch.position} }
    end
  end

  context 'scopes' do
    setup do
      Page.destroy_all
      @root          = Factory :page
      @children      = (1..5).map{ Factory :page }
      @root.children = @children
      @root.save and @root.reload
    end

    should 'getting siblings' do
      assert_equal @children[1..-1], @children.first.siblings
    end

    should 'getting root' do
      assert_equal [@root], Page.roots
    end
  end

  context 'paths and json generation' do
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

    should 'generate path' do
      @pages.each{ |p| p.save  }
      assert_equal @expected_path, @last.dup.generate_path
    end

    should 'save path' do
      assert_equal nil, @last.path
      @pages.each &:save
      assert_equal @expected_path, @last.path
    end

    should 'find by path' do
      @pages.each &:save
      assert_equal @last, Page.find_by_path(@last.path)
    end

    should 'override to json' do
      walk = lambda do |node|
        {:attributes => {'data-node-id' => node.id, :rel => node.is_page ? 'page' : 'section', 'data-path' => node.path, 'data-permalink' => node.permalink}, :data => node.title, :children => node.children.map{ |c| walk.call(c) }}
      end
      tree = walk.call @first
      assert_equal tree.to_json, @first.to_json
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

    should 'convert to blank if permalink == index' do
      @page = Factory :page, :permalink => 'index'
      assert_equal '', @page.permalink
    end
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
        @page1.save!
        @page2.generate_path
      end

      should  'not allow duplicate if path is the same and both are pages' do
        assert_equal @page1.path,      @page2.path
        assert_equal @page1.permalink, @page2.permalink
        assert_equal false, @page2.valid?
        assert_equal false, @page2.errors.on(:permalink).blank?
      end

      should 'allow duplicate if path is the same but one is not page' do
        @page1.update_attribute :is_page, false
        assert_equal @page1.path,      @page2.path
        assert_equal @page1.permalink, @page2.permalink
        @page1.save!
        assert_equal true, @page2.valid?
      end

      should 'allow duplicate if paths are diferent and both are pages' do
        @page2.parent = @page3
        @page2.generate_path
        assert_not_equal @page1.path,  @page2.path
        assert_equal @page1.permalink, @page2.permalink
        @page1.save!
        assert_equal true, @page2.valid?
      end

      should 'validate presence of permalink if is not page' do
        page = Factory.build :page, :permalink => '', :is_page => false
        assert_equal false, page.valid?
        assert_equal false, page.errors.on(:permalink).blank?
      end
    end
  end
end
