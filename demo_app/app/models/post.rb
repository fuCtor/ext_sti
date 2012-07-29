class Post < ActiveRecord::Base
  attr_accessible :name

  acts_as_ati :type, :class_name => PostType, :foreign_key => :post_type_id, :field_name => :name do |type|       
    "#{type}Post"
  end
  
  default_scope :include => :type, :joins => :type
    
end

