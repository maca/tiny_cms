class TinyCmsViewsGenerator < Rails::Generator::Base
  def initialize *args
    super
    @source_root = options[:source] || File.join(spec.path, '..', '..')
  end
  
  def manifest
    record do |m|
      m.directory "app/views"

      directory = nil
      Dir.glob("#{@source_root}/app/views/**/*.erb").each do |file|
        file = file.gsub("#{ @source_root }/", "")
        m.directory directory = File.dirname(file) if directory != File.dirname(file)
        m.file file, file
      end
    end
  end

end