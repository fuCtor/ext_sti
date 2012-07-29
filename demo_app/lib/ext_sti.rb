module ExtSTI
  
  def ati_type type
    superclass.association_inheritance[:type] = type
  end
  
  def acts_as_ati association_name = :type, params
    include InstanceMethods
    
    @association_inheritance = {
      :association => association_name,
      :field_name => (params[:field_name] || :name),
      :block => (block_given? ? Proc.new {|type| yield type }: Proc.new{ |type| type })
    }  
    
    params.delete :field_name
    
    belongs_to association_name, params
    validates reflect_on_association(association_name).foreign_key.to_sym, :presence => true

    before_validation :init_type

    class << self
      
      def inheritance_column
        "id" #HACK
      end
      
      def association_inheritance
        @association_inheritance
      end
      
      def instantiate(record)
        sti_class = find_sti_class(record)
        puts sti_class.inspect
        record_id = sti_class.primary_key && record[sti_class.primary_key]
        if ActiveRecord::IdentityMap.enabled? && record_id
          instance = use_identity_map(sti_class, record_id, record)
        else
          instance = sti_class.allocate.init_with('attributes' => record)
        end
        instance
      end

      def find_sti_class( record )
        association = reflect_on_association(@association_inheritance[:association])
        
        class_type = begin
          inheritance_record = association.klass.find(record[association.foreign_key.to_s])
          inheritance_record.send(@association_inheritance[:field_name].to_sym).camelize
        rescue ActiveRecord::RecordNotFound
          ""
        end

        super @association_inheritance[:block].call(class_type)
      end
    end
    
  end
  
    
  module InstanceMethods
    def init_type
      params = self.class.superclass.association_inheritance
      association = self.class.reflect_on_association(params[:association])
      
      type =  params[:type]|| self.class.to_s
      
      type_instance = begin
          association.klass.where(params[:field_name] => type).first!
        rescue ActiveRecord::RecordNotFound
          association.klass.create params[:field_name] => type
        end

      
      self.send "#{association.name}=", type_instance 
    end
  end
  
  
end