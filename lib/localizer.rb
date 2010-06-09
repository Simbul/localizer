module Localizer
  def localize(*attributes)
    attributes.each do |attribute|
      attr_s = attribute.to_s
      attrs_s = ActiveSupport::Inflector.pluralize(attr_s)
    
      has_many "localized_#{attrs_s}".to_sym, :conditions => {:attribute => attrs_s}, :as => :localized_model, :class_name => "LocalizedString", :dependent => :destroy, :autosave => true
    
      named_scope "with_local_#{attr_s}".to_sym, lambda { |*args|
        {:include => "localized_#{attrs_s}".to_sym, :conditions => {:localized_strings => {:locale => (args.first || I18n.locale.to_s)}}}
      }
    
      define_method "set_#{attr_s}" do |*params|
        unless (1..2).include? params.length
          raise ArgumentError.new("wrong number of arguments (#{params.length} for 1)")
        end
        value = params.first
        locale = params[1] || I18n.default_locale.to_s
      
        values = send("localized_#{attrs_s}".to_sym)
      
        localized_value = nil
        values.each do |l|
          localized_value = l if l.locale == locale
        end
        if localized_value
          localized_value.value = value
        else
          values << LocalizedString.new(:value => value, :locale => locale, :attribute => attrs_s)
        end
      end
    
      define_method "get_#{attr_s}" do |*params|
        unless params.length <= 2
          raise ArgumentError.new("wrong number of arguments (#{params.length} for 2)")
        end
        
        locale = params[0] || I18n.default_locale.to_s
        fallback = params[1] || false
        
        values = send("localized_#{attrs_s}".to_sym)
        
        output = ""
        if values.length == 1 and values.first.locale == locale
          # If the value is already available, don't query the DB
          output = values.first.value
        else
          localized_value = values.first(:conditions => {:locale => locale})
          output = localized_value.value unless localized_value.nil?
        end
        
        # Fallback on default locale (if required)
        output = method("get_#{attr_s}").call() if output.empty? and fallback and locale != I18n.default_locale.to_s
        
        return output
      end
      
      define_method "#{attrs_s}=" do |values|
        values.each do |locale, value|
          method("set_#{attr_s}").call(value, locale)
        end
      end
      
      define_method "#{attrs_s}" do
        localized_strings = send("localized_#{attrs_s}".to_sym)
        
        out = {}
        localized_strings.each do |localized_string|
          out[localized_string.locale] = localized_string.value
        end
        return out
      end
    
      define_method "update_localized_attribute_#{attr_s}" do |params|
        values = params.delete(attrs_s)
        method("#{attrs_s}=").call(values) if values
      end
      
    end
  end
  
  def validates_default_locale(*attributes)
    attributes.each do |attribute|
      attr_s = attribute.to_s
      attrs_s = ActiveSupport::Inflector.pluralize(attr_s)
      
      validates_each "localized_#{attrs_s}".to_sym do |model, attr, value|
        valid = false
        value.each do |ls|
          valid = true if ls.locale == I18n.default_locale.to_s and !ls.value.empty?
        end
        model.errors.add(attr, "is missing a value for the default locale (#{I18n.default_locale})") unless valid
      end
    end
  end
end
