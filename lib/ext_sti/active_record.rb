require 'active_record'

module ExtSTI
  module ActiveRecord
    def acts_as_ati_type( type = self.class.to_s, params = {} )
      base_param = base_class.association_inheritance
      
      params[:alias].each { |al|
        base_param[:alias][al.to_s.downcase.to_sym] = type  
      } if params[:alias]
      
      sti_params = self.association_inheritance
      
      sti_params[:type] = type
      sti_params[:id] = begin 
			base_param[:association].klass.where( base_param[:field_name] => type).first || 0  
		rescue   
			0
		end
      self.association_inheritance = sti_params      
    end
    
    def acts_as_ati( association_name = :type, params = {} )
      include InstanceMethods
      
      @association_inheritance = {
        id: 0,
        field_name: params[:field_name] || :name,
        block: block_given? ? Proc.new {|type| yield type } : Proc.new{ |type| type },
        class_cache: {},
        alias: {}
      }      
      params.delete :field_name
      
      @association_inheritance[:association] = belongs_to(association_name, params)
      validates @association_inheritance[:association].foreign_key.to_sym, :presence => true
  
      before_validation :init_type
      
      #@association_inheritance[:observer] = @association_inheritance[:association].klass.after_update do |type|
      #  @association_inheritance[:class_cache][type.id] = type.send(@association_inheritance[:field_name].to_sym).camelize
      #end          
  
      class << self
        
        def inheritance_column
          self.base_class.association_inheritance[:association].foreign_key.to_s
        end
        
        def association_inheritance
          @association_inheritance ||= base_class.association_inheritance.dup
        end
        
        def association_inheritance=( params )
          @association_inheritance = params
        end
        
        def new_by_type( type, params = {} )
           instance = find_sti_class(type.to_s.classify).new params
           
        end
        
        def create_by_type( type, params = {} )
           find_sti_class(type.to_s.classify).create params do |item|
             yield item if block_given?
           end
        end
        
        def instantiate( record )
          sti_class = find_sti_class(record)
          record_id = sti_class.primary_key && record[sti_class.primary_key]
          if ::ActiveRecord::IdentityMap.enabled? && record_id
            instance = use_identity_map(sti_class, record_id, record)
          else
            instance = sti_class.allocate.init_with('attributes' => record)
          end
          instance
        end
  
        def find_sti_class( record )
          params = self.association_inheritance          
          
          class_type =  if record.is_a? String
            (params[:alias][record.to_s.downcase.to_sym] || record).to_s.classify                        
          else
            association = params[:association]
            
            type_id = record[association.foreign_key.to_s]
            
              
            params[:class_cache][type_id] ||= begin
              inheritance_record = association.klass.find(type_id)       
              value = inheritance_record.send(params[:field_name].to_sym)
                      
              value = (params[:alias][value.to_s.downcase.to_sym] || value)              
              value.to_s.classify
            rescue ::ActiveRecord::RecordNotFound
              ''
            end
          end 
         
          super params[:block].call(class_type)
        end
              
        def relation #:nodoc:      
          @relation ||= ::ActiveRecord::Relation.new(self, arel_table)
          params = self.association_inheritance
          association = params[:association]
          
          if finder_needs_type_condition?
            type =  params[:type] || self.to_s
            type_id = params[:id] ||= association.klass.where(params[:field_name] => type).first          
                             
            @relation.where(association.foreign_key.to_sym => type_id )
          else
            @relation
          end
        end
        
      end
    end
    
      
    module InstanceMethods
      def init_type
        params = self.class.association_inheritance
        association = params[:association]
        begin                  
          type =  params[:type] || self.class.to_s
          
          type_instance = begin
              association.klass.where(params[:field_name] => type).first!
            rescue ::ActiveRecord::RecordNotFound
              association.klass.create params[:field_name] => type
            end
          
          self.send "#{association.name}=", type_instance 
        end unless self.send(association.name)
      end
    end  
  end
  
  ::ActiveRecord::Base.extend ActiveRecord
end
