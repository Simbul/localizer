require 'helper'
require 'lib/activerecord_test_case'

require 'localizer'
require 'localized_string'
class ActiveRecord::Base
  extend Localizer
end

module SharedSetup

  TRANSLATIONS = {
    :en => {
      :hello => "Hello"
    },
    :it => {
      :hello => "Ciao"
    }
  }

  def setup
    I18n.load_path = []
    I18n.backend = I18n::Backend::Simple.new
    I18n.default_locale = :en
    TRANSLATIONS.each{|l,t| I18n.backend.store_translations(l,t) }
  end

end

class LocalizerTest < ActiveRecordTestCase
  
  include SharedSetup
  
  fixtures :letters, :localized_strings, :posts
  
  def setup
    @l = Letter.new
  end
  
  def test_init
    @l = Letter.new
    
    assert @l.methods.include? "greetings"
    assert @l.methods.include? "greetings="
    assert @l.methods.include? "get_greeting"
    assert @l.methods.include? "set_greeting"
    assert @l.methods.include? "update_localized_attribute_greeting"
    
    # Check named scope
    assert Letter.respond_to?("with_local_greeting")
    
    assert @l.save!
  end
  
  def test_localized_string
    l = LocalizedString.new(
      :value => "Hello",
      :locale => I18n.default_locale.to_s,
      :localized_model_id => 1,
      :localized_model_type => "Letter",
      :attribute => "greetings"
    )
    assert l.valid?
    assert l.save!
    
    l = LocalizedString.new(
      :value => "Ciao",
      :locale => "it",
      :localized_model_id => 1,
      :localized_model_type => "Letter",
      :attribute => "greetings"
    )
    assert l.valid?
    assert l.save!
  end
  
  def test_localized_attrs
    assert_equal([], @l.localized_greetings)
    
    g = []
    g << LocalizedString.new(
      :value => "Hello",
      :locale => "en",
      :localized_model_id => @l.id,
      :localized_model_type => "Letter",
      :attribute => "greetings"
    )
    g << LocalizedString.new(
      :value => "Ciao",
      :locale => "it",
      :localized_model_id => @l.id,
      :localized_model_type => "Letter",
      :attribute => "greetings"
    )
    
    @l.localized_greetings = g
    assert @l.valid?
    
    assert_equal(g, @l.localized_greetings)
  end
  
  def test_attrs
    assert_equal({}, @l.greetings)
    
    g = {
      "en" => "Hello",
      "it" => "Ciao"
    }
    
    @l.greetings = g
    assert @l.valid?
    
    assert_equal(g, @l.greetings)
  end
  
  def test_getset_attr
    assert_equal("", @l.get_greeting("en"))
    assert_equal("", @l.get_greeting("it"))
    
    @l.set_greeting("Hello", "en")
    @l.set_greeting("Ciao", "it")
    
    assert @l.save! # TODO: saving shouldn't be required
    
    assert_equal("Hello", @l.get_greeting("en"))
    assert_equal("Ciao", @l.get_greeting("it"))
  end
  
  def test_set_default_attr
    @l.set_greeting("Hello")
    
    assert @l.save! # TODO: saving shouldn't be required
    
    assert_equal("Hello", @l.get_greeting(I18n.default_locale.to_s))
  end
  
  def test_get_default_attr
    @l.set_greeting("Hello", I18n.default_locale.to_s)
    
    assert @l.save! # TODO: saving shouldn't be required
    
    assert_equal("Hello", @l.get_greeting())
  end
  
  def test_fallback
    letter = letters(:letter01)
    
    assert_equal("", letter.get_greeting("it"))
    assert_equal("Hello", letter.get_greeting())
    
    # Falls back to default
    assert_equal("Hello", letter.get_greeting("it", true))
  end
  
  def test_named_scope
    I18n.locale = :en
    letters = Letter.with_local_greeting.all(:conditions => {:id => 2})
    assert_equal(1, letters.length)
    assert_equal({"en" => "Hello"}, letters.first.greetings)
    
    I18n.locale = :it
    letters = Letter.with_local_greeting.all(:conditions => {:id => 2})
    assert_equal(1, letters.length)
    assert_equal({"it" => "Ciao"}, letters.first.greetings)
  end
  
  def test_new_post
    params = {"titles" => {"en" => "Title EN"}}
    p = Post.new(params)
    assert p.valid?
    assert p.save!
  end
  
end
