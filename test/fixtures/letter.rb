class Letter < ActiveRecord::Base
  localize :greeting
  
  def update_attributes(params)
    update_localized_attribute_greeting(params)
    
    super(params)
  end
end
