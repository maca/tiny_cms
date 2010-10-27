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
      
      model.named_scope :exclude_by_id, lambda { |id| {:conditions => "id != #{id}"} }
      
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

      # dynamic routing
      model.before_save   :update_dynamic_route!
      model.after_destroy :remove_dynamic_route!

      model.find(:all, "dynamic_route IS NOT nil").each(&:update_dynamic_route!)
    end

    @@uuid = UUID.new

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
      section.exclude_by_id self.id
    end
    
    def section
      self.class.by_parent_id parent_id
    end
    
    def to_json opts = {}
      self.to_hash.to_json
    end

    # Dynamic routing
    def add_dynamic_route!
      controller, action = dynamic_route.split('#')
      self.dynamic_route_uuid = @@uuid.generate
      new_route = ActionController::Routing::Routes.builder.build(permalink, {:controller => controller, :action => action, :dynamic_route_uuid => dynamic_route_uuid})
      ActionController::Routing::Routes.routes.unshift new_route
    end

    def remove_dynamic_route!
      ActionController::Routing::Routes.routes.reject! { |r| r.instance_variable_get(:@requirements)[:dynamic_route_uuid] == dynamic_route_uuid } unless dynamic_route_uuid.blank?
    end

    def update_dynamic_route!
      remove_dynamic_route!
      add_dynamic_route! unless dynamic_route.blank?
    end
  end
end
