class TinyCmsCreate<%= table_name.camelize %> < ActiveRecord::Migration
  def self.up
    create_table :<%= table_name %> do |t|
      t.integer  :parent_id
      t.string   :permalink
      t.integer  :position
      t.string   :title
      t.string   :content
      
      t.timestamps
    end
  end

  def self.down
    drop_table :<%= table_name %>
  end
end