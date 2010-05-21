class TinyCmsAssetsGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      m.directory "config/locales"
      m.file '../../../lib/tiny_cms/tiny_cms.en.yml', 'config/locales/tiny_cms.en.yml'
      
      m.directory "public/javascripts/jquery-tree/jquery-tree-plugins"

      %w(jquery-1.4.2.min.js jquery-ui-dialog.js pages.js).each do |file|
        m.file "javascripts/#{file}", "public/javascripts/#{file}"      
      end
      
      %w(jquery-tree-plugins/jquery.tree.contextmenu.js jquery.tree.min.js).each do |file|
        m.file "javascripts/jquery-tree/#{file}", "public/javascripts/jquery-tree/#{file}"      
      end
      
      directory = nil
      Dir.glob("#{ spec.path }/templates/stylesheets/**/*.*").each do |file|
        file = file.gsub("#{ spec.path }/templates/", '')
        m.directory directory = "public/#{ File.dirname(file) }" if directory != "public/#{ File.dirname(file) }"
        m.file file, "public/#{ file }"
      end
    end
  end
end