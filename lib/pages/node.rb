module Pages
  module Node
    module ClassMethods
      def reorder ids
        ids.each_with_index{ |id, index| 
          find(id).update_attributes :position => index, :parent_id => nil #TODO: Too unefficient
        }
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
      model.named_scope :pages,   :conditions => {:is_page   => true}
      
      model.belongs_to :parent,   :class_name => model.to_s, :foreign_key => 'parent_id'
      model.has_many   :children, :class_name => model.to_s, :foreign_key => 'parent_id', :order => 'position', :dependent => :destroy
      
      model.validates_presence_of   :title
      # model.validates_presence_of   :permalink, :unless => :is_page
      model.validates_uniqueness_of :permalink, :scope  => [:parent_id]

      model.validate :validates_no_children, :if => :is_page

      model.before_validation :parameterize_permalink
      
      model.send :define_method, :children_with_position= do |array|
        # table = self.class.to_s.tableize
        # sql = <<-SQL
        #   UPDATE "#{table}"
        #     SET "position" = CASE id
        #       #{ array.map{ |child| "WHEN #{child.id} THEN #{ array.index(child) }"}.join("\n") }
        #     END
        #   WHERE "#{table}"."id" IN (#{ array.map(&:id).join(', ') })
        # SQL
        # ActiveRecord::Base.connection.execute sql
        
        array.each_with_index{ |child, index| child.update_attribute :position, index } # TODO: Too unefficient
        self.children_without_position = array
      end
      model.alias_method_chain :children=, :position
    end

    def rel= rel
      self.is_page = rel == 'page'
    end
  
    def siblings
      return [] unless parent_id
      self.class.include_tree(1).find(:first, :conditions => "id = #{parent_id}").children.find(:all, :conditions => "id != #{id}")
    end
    
    def parameterize_permalink
      text = permalink.blank? ? title : permalink
      self.permalink = text.parameterize if text
    end
    
    def path
      "#{ parent.path if parent }/#{ permalink }"
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