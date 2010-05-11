module Pages
  module Node
    module ClassMethods
      def reorder ids
        ids.each_with_index{ |id, index| 
          find(id).update_attributes :position => index, :parent_id => nil #TODO: This is so unefficient
        }
      end
    end
    
    def self.included model
      model.extend ClassMethods
      
      model.named_scope :include_tree, lambda { |depth|
        children = :children and 2.upto(depth){ nest = {:children => nest} }
        {:include => children}
      }
      model.named_scope :roots,   :conditions => {:parent_id => nil}, :order => 'position'
      model.named_scope :pages,   :conditions => {:is_page   => true}
      
      model.belongs_to :parent,   :class_name => model.to_s, :foreign_key => 'parent_id'
      model.has_many   :children, :class_name => model.to_s, :foreign_key => 'parent_id', :order => 'position', :dependent => :destroy
      model.accepts_nested_attributes_for :children, :allow_destroy => true
      
      model.validates_presence_of   :title
      model.validates_presence_of   :permalink, :unless => :is_page
      model.validates_uniqueness_of :permalink, :scope  => [:is_page, :path]
      
      model.validate :validates_no_children, :if => :is_page
      
      model.before_validation :parameterize_permalink, :generate_path
      # model.before_save :propagate_path_update
      
      model.send :define_method, :children_with_position= do |array|
        array.each_with_index{ |child, index| child.update_attribute :position, index } # TODO: Shouldn't need to save individually
        self.children_without_position = array
      end
      model.alias_method_chain :children=, :position
 
      model.send :define_method, :children_attributes_with_position= do |attrs|
        attrs = attrs.values if Hash === attrs
        attrs.each_with_index { |ch_attrs, index| ch_attrs.symbolize_keys! and ch_attrs[:position] = index }
        self.children_attributes_without_position = attrs
      end
      model.alias_method_chain :children_attributes=, :position
    end
    
    # def propagate_path_update root = true
    #   descendents = 
    #   if root
    #     children.include_tree(5)
    #   else
    #     self.update_attribute(:path, "#{ parent.generate_path if parent }/#{ permalink }") 
    #     children
    #   end
    #   descendents.each do |child|
    #     child.propagate_path_update false
    #   end
    # end
    
    def rel= rel
      self.is_page = rel == 'page'
    end
  
    def siblings
      parent.children.reject{ |ch| ch.id === id }
    end
    
    def parameterize_permalink
      text = permalink || title
      text = '' if text == 'index'
      self.permalink = text.parameterize.to_s if text
    end
    
    def generate_path
      self.path = "#{ parent.generate_path if parent }/#{ permalink }"
    end
    
    def to_hash
      {:attributes => {'data-node-id' => id, :rel => is_page ? 'page' : 'section', 'data-permalink' => permalink, 'data-path' => path}, :data => title, :children => children.map{ |c| c.to_hash } }
    end
    
    def to_json opts = {}
      self.to_hash.to_json
    end
    
    private
    def validates_no_children
      errors.add(:base, "A page cannot have children") unless children.blank? # Todo: localize
    end
  end
end