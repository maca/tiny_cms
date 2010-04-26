module Pages
  module Node
    module ClassMethods
      def order models
        models.each_with_index{ |model, index| model.update_attribute :order, index }
      end
    end
    
    def self.included model
      model.extend ClassMethods
      
      model.named_scope :include_tree, :include => {{:children => {:children => {:children => :children}}}, :parent}
      model.named_scope :roots, :conditions => {:parent_id => nil}, :order => 'position'
      
      model.belongs_to :parent,   :class_name => model.to_s, :foreign_key => 'parent_id'
      model.has_many   :children, :class_name => model.to_s, :foreign_key => 'parent_id', :order => 'position', :dependent => :destroy
      model.accepts_nested_attributes_for :children, :allow_destroy => true
      
      model.before_save :generate_path
      
      model.send :define_method, :children_with_position= do |array|
        array.each_with_index{ |child, index| child.position = index }
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
  
    def siblings
      parent.children.reject{ |ch| ch.id === id }
    end
    
    def generate_path
      self.path = "#{ parent.generate_path if parent }/#{ permalink }"
    end
  end
end