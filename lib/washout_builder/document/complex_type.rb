module WashoutBuilder
  module Document
    module ComplexType
      extend ActiveSupport::Concern
      
      
      def get_complex_class_name(defined = [])
        complex_class =  struct? ? basic_type : nil
        complex_class =  complex_class.include?(".") ? complex_class.gsub(".","/").camelize : complex_class.classify    unless complex_class.nil?
     
        unless complex_class.nil? || defined.blank?
     
          complex_obj_found = defined.detect {|hash|   hash[:class] == complex_class}
    
          if !complex_obj_found.nil? && struct?  &&  !classified?
            raise RuntimeError, "Duplicate use of `#{basic_type}` type name. Consider using classified types."
          end
        end
   
        return complex_class
      end
      
      def get_param_structure
        map.inject({}) {|h,element|  h[element.name] = element.type;h }
      end
  
  
      def remove_type_inheritable_elements( keys)
        self.map =  self.map.delete_if{|element|  keys.include?(element.name) }
      end
  
      #      def get_ancestor_structure
      #        {self.class.to_s.downcase =>  self.class.columns_hash.inject({}) {|h, (k,v)|  h["#{k}"]="#{v.type}".to_sym; h } }
      #      end
      
      
      def fix_descendant_wash_out_type(config, complex_class)
        param_class = complex_class.is_a?(Class) ? complex_class : complex_class.constantize rescue nil
        if !param_class.nil? && param_class.ancestors.include?(WashOut::Type) && !map[0].nil? 
          descendant = WashOut::Param.parse_builder_def(config, param_class.wash_out_param_map)[0]
          self.name =  descendant.name 
          self.map = descendant.map
        end
      end
      
     
      def  same_structure_as_ancestor?(ancestor)
        param_structure = get_param_structure
        ancestor_structure = ancestor.get_param_structure
        if  param_structure.keys == ancestor_structure.keys
          return true
        else 
          remove_type_inheritable_elements( ancestor_structure.keys)
          return false
        end
      end
  
         
      def get_ancestors(class_name)
        param_class = class_name.is_a?(Class) ? class_name : class_name.constantize rescue nil
        if  param_class.nil?
          return nil
        else
          (param_class.ancestors - param_class.included_modules).delete_if{ |x| x.to_s.downcase == class_name.to_s.downcase  ||  x.to_s == "ActiveRecord::Base" ||  x.to_s == "Object" || x.to_s =="BasicObject" || x.to_s == "WashOut::Type" }
        end
      end
  
      
    
      def get_nested_complex_types(config,defined)
        defined = [] if defined.blank?
        complex_class = get_complex_class_name( defined)
        fix_descendant_wash_out_type( config, complex_class)
        defined << {:class =>complex_class, :obj => self, :ancestors => classified?  ?  get_class_ancestors(config, complex_class, defined) : nil } unless complex_class.nil?
        if struct?
          c_names = []
          map.each { |obj|   c_names.concat(obj.get_nested_complex_types(config, defined))  }        
          defined.concat(c_names)
        end
        defined.sort_by { |hash| hash[:class].to_s.downcase }.uniq unless defined.blank?
      end
     
    
      def get_class_ancestors( config, class_name, defined)
        bool_the_same = false
        ancestors   = get_ancestors(class_name)
        unless ancestors.blank?
          ancestor_structure =   { ancestors[0].to_s.downcase => ancestors[0].wash_out_param_map }
          ancestor_object =  WashOut::Param.parse_def(config,ancestor_structure)[0]
          bool_the_same = same_structure_as_ancestor?( ancestor_object)
          unless bool_the_same
            top_ancestors = get_class_ancestors(config, ancestors[0], defined)
            defined << {:class =>ancestors[0], :obj =>ancestor_object ,  :ancestors => top_ancestors   }
          end
          ancestors unless  bool_the_same
        end
      end
  
  
    end
  end
end