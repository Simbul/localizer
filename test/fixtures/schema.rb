ActiveRecord::Schema.define do
  
  create_table "localized_strings", :force => true do |t|
    t.string :value
    t.string :locale
    t.integer :localized_model_id
    t.string :localized_model_type
    t.string :attribute

    t.timestamps
  end
  
  create_table "letters", :force => true do |t|
    t.string :content
    
    t.timestamps
  end

end
