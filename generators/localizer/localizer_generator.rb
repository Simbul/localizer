class LocalizerGenerator < Rails::Generator::Base
  attr_accessor :migration_name
 
  def manifest    
    file_name = "create_localized_strings"
    @migration_name = file_name.camelize
    
    record do |m|
      m.migration_template "localizer_migration.rb.erb",
                           File.join('db', 'migrate'),
                           :migration_file_name => file_name
    end
  end 
  
end
