class Post < ActiveRecord::Base
  localize :title, :content
  
  validates_default_locale :title
end