module ExtSTI
  
  def ati_type type = self.class.to_s
    params = base_class.association_inheritance.dup
    
    params[:type] = type
    params[:id] = params[:association].klass.where( params[:field_name] => type).first || 0
    
    self.association_inheritance = params    
  end
  
  def acts_as_ati association_name = :type, params
    include InstanceMethods
    
    @association_inheritance = {
      :id => 0,
      :field_name => (params[:field_name] || :name),
      :block => (block_given? ? Proc.new {|type| yield type }: Proc.new{ |type| type }),
      :class_cache => {}
    }      
    params.delete :field_name
    
    @association_inheritance[:association] = belongs_to(association_name, params)
    validates @association_inheritance[:association].foreign_key.to_sym, :presence => true

    before_validation :init_type    

    class << self
      
      def inheritance_column
        self.base_class.association_inheritance[:association].foreign_key.to_s
      end
      
      def association_inheritance
        @association_inheritance
      end
      
      def association_inheritance= params
        @association_inheritance = params
      end
      
      def instantiate(record)
        sti_class = find_sti_class(record)
        record_id = sti_class.primary_key && record[sti_class.primary_key]
        if ActiveRecord::IdentityMap.enabled? && record_id
          instance = use_identity_map(sti_class, record_id, record)
        else
          instance = sti_class.allocate.init_with('attributes' => record)
        end
        instance
      end

      def find_sti_class( record )
        params = self.base_class.association_inheritance
        association = params[:association]
        
        type_id = record[association.foreign_key.to_s]
        class_type = params[:class_cache][type_id] ||= begin
          inheritance_record = association.klass.find(type_id)       
          inheritance_record.send(params[:field_name].to_sym).camelize
        rescue ActiveRecord::RecordNotFound
          ""
        end

        super params[:block].call(class_type)
      end
            
      def relation #:nodoc:      
        @relation ||= ::ActiveRecord::Relation.new(self, arel_table)
        params = self.association_inheritance
        association = params[:association]
        
        if finder_needs_type_condition?
          type =  params[:type] || sti_class.to_s
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
      
      type =  params[:type] || sti_class.to_s
      
      type_instance = begin
          association.klass.where(params[:field_name] => type).first!
        rescue ActiveRecord::RecordNotFound
          association.klass.create params[:field_name] => type
        end
      
      self.send "#{association.name}=", type_instance 
    end
  end  
  
end