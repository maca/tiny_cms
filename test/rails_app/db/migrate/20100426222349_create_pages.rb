class CreatePages < ActiveRecord::Migration
  def self.up
    create_table :pages do |t|
      t.integer  :parent_id
      t.string   :permalink
      t.string   :path
      t.integer  :position
      t.string   :title
      t.string   :content
      t.boolean  :is_page

      t.timestamps
    end
  end

  def self.down
    drop_table :pages
  end
end
