require_relative './shared_complex_type'
module WashoutBuilder
  module Document
    module ExceptionModel
      extend ActiveSupport::Concern
      include WashoutBuilder::Document::SharedComplexType

      def self.included(base)
        base.send :include, WashoutBuilder::Document::SharedComplexType
      end

      def get_fault_class_ancestors(defined, _debug = false)
        bool_the_same = false
        ancestors = fault_ancestors
        if ancestors.blank?
          defined << fault_ancestor_hash(find_fault_model_structure, [])
        else
          defined << fault_ancestor_hash(fault_without_inheritable_elements(ancestors), ancestors)
          ancestors[0].get_fault_class_ancestors(defined)
        end
        ancestors unless bool_the_same
      end

      def fault_without_inheritable_elements(ancestors)
        remove_fault_type_inheritable_elements(ancestors[0].find_fault_model_structure.keys)
      end

      def fault_ancestors
        get_complex_type_ancestors(self, ['ActiveRecord::Base', 'Object', 'BasicObject', 'Exception'])
      end

      def fault_ancestor_hash(structure, ancestors)
        { fault: self, structure: structure, ancestors: ancestors }
      end

      def remove_fault_type_inheritable_elements(keys)
        find_fault_model_structure.delete_if { |key, _value| keys.include?(key) }
      end

      def check_valid_fault_method?(method)
        method != :== && method != :! &&
          (instance_methods.include?(:"#{method}=") ||
            instance_methods.include?(:"#{method}")
          )
      end

      def find_fault_attributes
        attrs = []
        attrs = instance_methods(nil).map do |method|
          method.to_s if check_valid_fault_method?(method)
        end
        attrs = attrs.delete_if { |method| method.end_with?('=') && attrs.include?(method.delete('=')) }
        attrs.concat(%w(message backtrace))
      end

      def get_fault_type_method(method_name)
        case method_name.to_s.downcase
          when 'code'
            'integer'
          when 'message', 'backtrace'
            'string'
          else
            'string'
          end
      end

      def find_fault_model_structure
        h = {}
        find_fault_attributes.each do |method_name|
          method_name = method_name.to_s.end_with?('=') ? method_name.to_s.delete('=') : method_name
          primitive_type = get_fault_type_method(method_name)
          h["#{method_name}"] = {
            primitive: "#{primitive_type}",
            member_type: nil
          }
        end
        h
      end
    end
  end
end
