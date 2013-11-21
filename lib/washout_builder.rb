require 'wash_out'
require 'washout_builder/soap_fault'
require 'washout_builder/soap'
require 'washout_builder/param'
require 'washout_builder/engine'
require 'washout_builder/dispatcher'
require 'washout_builder/type'


module ActionDispatch::Routing
  class  Mapper

    alias_method  :original_wash_out,:wash_out

    # Adds the routes for a SOAP endpoint at +controller+.
    def wash_out(controller_name, options={})
      options.reverse_merge!(@scope) if @scope
      controller_class_name = [options[:module], controller_name].compact.join("/")

      match "#{controller_name}/doc"   => "#{controller_name}#_generate_doc", :via => :get, :format => false
      original_wash_out(controller_name, options)


    end
  end
end




Mime::Type.register "application/soap+xml", :soap
ActiveRecord::Base.send :extend, WashOut::Model if defined?(ActiveRecord)

WashOut::Param.class_eval do
  alias_method :original_initialize, :initialize
  include WashoutBuilder::Param if defined?(WashoutBuilder::Param)
end

ActionController::Renderers.add :soap do |what, options|
  _render_soap(what, options)
end

ActionController::Base.class_eval do

  # Define a SOAP service. The function has no required +options+:
  # but allow any of :parser, :namespace, :wsdl_style, :snakecase_input,
  # :camelize_wsdl, :wsse_username, :wsse_password and :catch_xml_errors.
  #
  # Any of the the params provided allows for overriding the defaults
  # (like supporting multiple namespaces instead of application wide such)
  #
  def self.soap_service(options={})
    include WashoutBuilder::SOAP
    self.soap_config = options
  end
end
