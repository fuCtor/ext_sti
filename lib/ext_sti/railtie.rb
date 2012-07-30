require 'ext_sti'
# 


module ExtSTI
  module ActiveRecord    
  end
  
  class Railtie < Rails::Railtie    
    initializer "ext_sti" do |app|
      ActiveSupport.on_load(:active_record) do
        #raise "ext_sti load4" 
        require 'ext_sti/active_record'             
      end
    end
  end
end