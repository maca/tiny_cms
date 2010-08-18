module TinyCMS
  module Node
    module ClassMethods
      def reorder ids, parent_id = nil
        transaction do
          ids.each_with_index { |id, index| find(id).update_attributes!(:position => index, :parent_id => parent_id) } #TODO: Unefficient but can live with it
        end
        return true
      rescue
        false
      end
    end
    
    def self.included model
      model.extend ClassMethods
      
      model.named_scope :include_tree, lambda { |depth|
        children = :children 
        2.upto(depth){ children = {:children => children} }
        {:include => children}
      }
      
      model.named_scope :by_path, lambda { |path|
        next {:conditions => {:permalink => path.last}} if path.size - 1 == 0
        parents = :parent
        2.upto(path.size - 1){ parents = {:parent => parents} }
        {:joins => parents, :conditions => {:permalink => path.last, 'parents_pages.permalink' => path[-2]}}
      }
      
      model.named_scope :roots,   :conditions => {:parent_id => nil}, :order => 'position'
      
      model.named_scope :by_parent_id, lambda { |parent_id|
        {:conditions => {:parent_id => parent_id}}
      }
      
      model.belongs_to :parent,   :class_name => model.to_s, :foreign_key => 'parent_id'
      model.has_many   :children, :class_name => model.to_s, :foreign_key => 'parent_id', :order => 'position', :dependent => :destroy
      
      model.validates_presence_of   :title
      model.validates_uniqueness_of :permalink, :scope  => [:parent_id]

      model.validates_associated :children

      model.before_validation :parameterize_permalink
      
      model.send :attr_accessor, :rel # Does nothing but jstree sends attribute
      
      model.send :define_method, :children_with_position= do |array|
        # TODO: Too unefficient
        transaction { array.each_with_index{ |child, index| child.update_attributes! :position => index, :parent_id => id } } rescue nil
        self.children_without_position = array
      end
      model.alias_method_chain :children=, :position
    end
   
    def parameterize_permalink
      text = permalink.blank? ? title : permalink
      self.permalink = text.parameterize if text
    end
    
    def path
      "#{ parent.path if parent }/#{ permalink }"
    end
    
    def to_hash
      {:attributes => {'data-node-id' => id, 'data-permalink' => permalink, 'data-path' => path}, :data => title, :children => children.map{ |c| c.to_hash } }
    end
    
    def siblings
      section.find :all, :conditions => "id != #{id}"
    end
    
    def section
      self.class.by_parent_id parent_id
    end
    
    def to_json opts = {}
      self.to_hash.to_json
    end
  end
end