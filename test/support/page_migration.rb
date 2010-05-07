
ActiveRecord::Migration.verbose       = false
# ActiveRecord::Base.logger             = Logger.new nil
ActiveRecord::Base.establish_connection :adapter => "sqlite3", :database => ":memory:"

ActiveRecord::Schema.define(:version => 1) do

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