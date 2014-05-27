module WashoutBuilder
  module Document
    module ExceptionModel
      extend ActiveSupport::Concern
      include WashoutBuilder::Document::SharedComplexType  
      
      def self.included(base)
        base.send :include, WashoutBuilder::Document::SharedComplexType
      end
      
      def get_fault_class_ancestors( defined, debug = false)
        bool_the_same = false
        ancestors  = fault_ancestors
        if  ancestors.blank?
          defined << fault_ancestor_hash(get_virtus_model_structure, []) 
        else
          defined << fault_ancestor_hash(fault_without_inheritable_elements(ancestors), ancestors)
          ancestors[0].get_fault_class_ancestors( defined)
        end
        ancestors unless  bool_the_same
      end
      
           
      def fault_without_inheritable_elements(ancestors)
        remove_fault_type_inheritable_elements(  ancestors[0].get_virtus_model_structure.keys)
      end
      
      def fault_ancestors
        get_complex_type_ancestors(self, ["ActiveRecord::Base", "Object", "BasicObject",  "Exception" ])
      end
      
      def fault_ancestor_hash( structure, ancestors)
        {:fault => self,:structure =>structure  ,:ancestors => ancestors   }
      end
      
      def remove_fault_type_inheritable_elements( keys)
        get_virtus_model_structure.delete_if{|key,value|  keys.include?(key) }
      end
       
      
      def attr_details_array?(attr_details)
        attr_details[:primitive].to_s.downcase == "array" 
      end
      
      def attr_details_basic_type?(attr_details, field)
        WashoutBuilder::Type::BASIC_TYPES.include?(attr_details[field.to_sym].to_s.downcase)
      end
      
      def get_virtus_member_type_primitive(attr_details)
        complex_class = nil
        if attr_details_array?(attr_details) && !attr_details_basic_type?(attr_details, "member_type")
          complex_class = attr_details[:member_type]
        elsif !attr_details_array?(attr_details) && !attr_details_basic_type?(attr_details, "primitive")
          complex_class = attr_details[:primitive]
        end
        complex_class
      end
 
      
      def get_exception_attributes
        attrs = self.instance_methods.find_all do |method|
          method != :== &&
            method != :! &&
            self.instance_methods.include?(:"#{method}=") 
        end
        attrs.concat(["message", "backtrace"])
      end
      
      
      def get_virtus_model_structure
        h = {}
        get_exception_attributes.each do |method_name|
          primitive_type = case method_name.to_s.downcase
          when "code" 
             "integer"
          when "message", "backtrace"
             "string"
          else
             "string"
          end
          h["#{method_name}"]= { 
            :primitive => "#{primitive_type}", 
            :member_type => nil
          }
        end
        return h
      end
      
      
      def self.extract_nested_complex_types(complex_class, complex_types)
        unless complex_class.nil?
          param_class = complex_class.is_a?(Class) ? complex_class : complex_class.constantize rescue nil
          if param_class.present? && WashoutBuilder::Type.valid_fault_class?(param_class)
            param_class.send :extend, WashoutBuilder::Document::ExceptionModel
            param_class.get_fault_class_ancestors( complex_types)
          elsif param_class.present? && !WashoutBuilder::Type.valid_fault_class?(param_class)
            raise RuntimeError, "Non-existent use of `#{param_class}` type name or this class does not inherit from SoapError. Consider using classified types that include SoapError  for exception classes."
          end 
        end
      end
      
    end
  end
end