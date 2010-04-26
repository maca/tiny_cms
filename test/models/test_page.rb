require 'helper'

class PageTest < Test::Unit::TestCase
  should_belong_to :parent
  should_have_many :children
  
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
      should_change "Page.count", :from => 6, :to => 0
    end
  end

  context 'nested attributes for children' do
    setup do
      Page.destroy_all
      @root                     = Factory :page
      @children_attributes      = (1..5).map { Factory.attributes_for :page }
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
  
  context 'named scopes' do
    setup do
      Page.destroy_all
      @root          = Factory :page
      @children      = (1..5).map{ Factory :page }
      @root.children = @children
      @root.save and @root.reload
    end
    
    should 'get siblings' do
      assert_equal @children[1..-1], @children.first.siblings
    end
    
    should 'get root' do
      assert_equal [@root], Page.roots
    end
  end
  
  context 'paths' do
    setup do
      Page.destroy_all
      root   = Factory.build :page
      @pages = (1..5).map{ Factory.build :page }
      
      @pages.inject(root){ |parent, child| parent.children.push(child) and child }
      @pages.unshift root
      
      @last          = @pages.last
      @expected_path = "/#{@pages.map{ |p| p.permalink }.join('/')}" 
    end
    
    should 'generate path' do
      @pages.each{ |p| p.save  }
      assert_equal @expected_path, @last.dup.generate_path
    end
    
    should 'save path' do
      assert_equal nil, @last.path
      @pages.each(&:save)
      assert_equal @expected_path, @last.path
    end
    
    should 'find by path' do
      @pages.each(&:save)
      assert_equal @last, Page.find_by_path(@last.path)
    end
  end
end
