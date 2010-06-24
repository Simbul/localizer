class Letter < ActiveRecord::Base
  localize :greeting, :available_locales => [:en, :it, :jp]
  
  def update_attributes(params)
    update_localized_attribute_greeting(params)
    
    super(params)
  end
end
