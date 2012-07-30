module ExtSTI  
end

if defined?(Rails::Railtie)
  require 'ext_sti/railtie'
elsif defined?(Rails::Initializer)
  raise "ext_sti is not compatible with Rails 2.3 or older"
end
