module Localizer
  def localize(*attributes)
    available_locales = I18n.available_locales
    
    if attributes.last.is_a?(Hash)
      options = attributes.pop()
      available_locales = options[:available_locales] if options and options.has_key? :available_locales
    end
    
    attributes.each do |attribute|
      attr_s = attribute.to_s
      attrs_s = ActiveSupport::Inflector.pluralize(attr_s)
      
      has_many "localized_#{attrs_s}".to_sym, :conditions => {:attribute => attrs_s}, :as => :localized_model, :class_name => "LocalizedString", :dependent => :destroy, :autosave => true
      
      available_locales.each do |locale|
        has_one "localized_#{attrs_s}_#{locale}".to_sym, :conditions => {:attribute => attrs_s, :locale => locale.to_s}, :as => :localized_model, :class_name => "LocalizedString", :dependent => :destroy
      end
      
      named_scope "with_local_#{attr_s}".to_sym, lambda { |*args|
        locale = args.first || I18n.locale.to_s
        {:include => "localized_#{attrs_s}_#{locale}".to_sym}
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
          send("localized_#{attrs_s}_#{locale}".to_sym).value = value
        else
          ls = LocalizedString.new(:value => value, :locale => locale, :attribute => attrs_s)
          values << ls
          send("localized_#{attrs_s}_#{locale}=".to_sym, ls)
        end
      end
      
      define_method "get_#{attr_s}" do |*params|
        unless params.length <= 2
          raise ArgumentError.new("wrong number of arguments (#{params.length} for 2)")
        end
        
        locale = params[0] || I18n.default_locale.to_s
        fallback = params[1] || false
        
        value = send("localized_#{attrs_s}_#{locale}".to_sym)
        
        output = ""
        
        # If the value is already available, don't query the DB
        output = value.value if value
        
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
