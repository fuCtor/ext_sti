[![endorse](https://api.coderwall.com/fuctor/endorsecount.png)](https://coderwall.com/fuctor)
ExtSTI
=======

Extending STI with inheritance through association.


Usage
------------
	
Gemfile:

	gem 'ext_sti', :git => 'git://github.com/fuCtor/ext_sti.git'

Models:

    class Post < ActiveRecord::Base
        attr_accessible :name

        acts_as_ati :type, :class_name => PostType, :foreign_key => :post_type_id, :field_name => :name do |type|       
            "#{type}Post"
        end    
    end

    class ForumPost < Post
        attr_accessible :name    
        ati_type :forum
    end
    
    class BlogPost < Post
        attr_accessible :name  
        ati_type :blog
    end
    
[![githalytics.com alpha](https://cruel-carlota.pagodabox.com/b283ce6c5951ab702477bf0743b5db3f "githalytics.com")](http://githalytics.com/fuCtor/ext_sti)
