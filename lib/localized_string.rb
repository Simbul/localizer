class LocalizedString < ActiveRecord::Base
  belongs_to :localized_model, :polymorphic => true
  
  validates_presence_of :value
  validates_inclusion_of :locale, :in => I18n.available_locales.map { |l| l.to_s }
end
