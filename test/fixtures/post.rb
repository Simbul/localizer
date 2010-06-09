class Post < ActiveRecord::Base
  localize :title, :content
  
  validates_default_locale :title
  
  def update_attributes(params)
    update_localized_attribute_title(params)
    update_localized_attribute_content(params)
    
    super(params)
  end
end