require 'localizer'
require 'active_support/inflector'

class ActiveRecord::Base
  extend Localizer
end