module WashoutBuilder
  module Param
    extend ActiveSupport::Concern

    def parse_builder_def(soap_config, definition)
      raise '[] should not be used in your params. Use nil if you want to mark empty set.' if definition == []
      return [] if definition.blank?

      # the following lines was removed because when generating the documentation
      #  the "source_class" attrtibute of the object was not the name of the class of the complex tyoe
      # but instead was the name given in the hash
      # Example :
      #  class ProjectType < WashOut::Type
      #  map :project => {
      # :name                                    => :string,
      #  :description                           => :string,
      #  :users                                    => [{:mail => :string }],
      #  }
      # end
      #
      # The name of the complex type should be ProjectType and not "project"

      #     if definition.is_a?(Class) && definition.ancestors.include?(WashOut::Type)
      #        definition = definition.wash_out_param_map
      #    end

      definition = { value: definition } unless definition.is_a?(Hash) # for arrays and symbols

      definition.map do |name, opt|
        if opt.is_a? self
          opt
        elsif opt.is_a? Array
          new(soap_config, name, opt[0], true)
        else
          new(soap_config, name, opt)
        end
      end
    end
  end
end
