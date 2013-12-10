module WashoutBuilderHelper
  include WashOutHelper

  def get_complex_class_name(p, defined = [])
    complex_class =  p.struct? ? p.basic_type : nil
    complex_class =  complex_class.include?(".") ? complex_class.gsub(".","/").camelize : complex_class.to_s.classify    unless complex_class.nil?
     
    unless complex_class.nil? || defined.blank?
     
      complex_obj_found = defined.detect {|hash|   hash[:class] == complex_class}
    
      if !complex_obj_found.nil? && p.struct?  &&  !p.classified? && p.source_class_name.blank?
        raise RuntimeError, "Duplicate use of `#{p.basic_type}` type name. Consider using classified types."
      end
    end
   
    return complex_class
  end

  
  def get_param_structure(param)
    param.map.inject({}) {|h,element|  h[element.name] = element.type;h }
  end
  
  
  def remove_type_inheritable_elements(param, keys)
    param.map.delete_if{|element|  keys.include?(element.name) }
  end
  
  
  def  same_structure_as_ancestor?(param, ancestor)
    param_structure = get_param_structure(param)
    ancestor_structure = get_param_structure(ancestor)
    if  param_structure.keys == ancestor_structure.keys
      return true
    else 
      remove_type_inheritable_elements(param, ancestor_structure.keys)
      return false
    end
  end
  
  
  
  
  def get_class_ancestors(param,class_name, defined)
    bool_the_same = false
    param_class = class_name.is_a?(Class) ? class_name : class_name.constantize 
    ancestors  = (param_class.ancestors - param_class.included_modules).delete_if{ |x| x.to_s.downcase == class_name.to_s.downcase  ||  x.to_s == "ActiveRecord::Base" ||  x.to_s == "Object" || x.to_s =="BasicObject" || x.to_s == "WashOut::Type" }
    unless ancestors.blank?
      ancestor_structure =  { ancestors[0].to_s.downcase =>  ancestors[0].columns_hash.inject({}) {|h, (k,v)|  h["#{k}"]="#{v.type}".to_sym; h } }
      ancestor_object =  WashOut::Param.parse_def(@soap_config,ancestor_structure)[0]
      bool_the_same = same_structure_as_ancestor?(param, ancestor_object)
      unless bool_the_same
        top_ancestors = get_class_ancestors(ancestor_class, defined)
        defined << {:class =>ancestor_class.to_s, :obj =>ancestor_object ,  :ancestors => top_ancestors   }
      end
    end
    ancestors unless  bool_the_same
  end
  
  
  def fix_descendant_wash_out_type(param, complex_class)
    param_class = complex_class.is_a?(Class) ? complex_class : complex_class.constantize rescue nil
    if !param_class.nil? && param_class.ancestors.include?(WashOut::Type) && !param.map[0].nil? 
      descendant = WashOut::Param.parse_def(@soap_config, param_class.wash_out_param_map)[0]
      param.name =  descendant.name 
      param.map = descendant.map
    end
  end

  def get_nested_complex_types(param, defined)
    defined = [] if defined.blank?
    complex_class = get_complex_class_name(param, defined)
    fix_descendant_wash_out_type(param, complex_class)
    defined << {:class =>complex_class, :obj => param, :ancestors => param.classified?  ?  get_class_ancestors(param, complex_class, defined) : nil } unless complex_class.nil?
    if param.struct?
      c_names = []
      param.map.each { |obj|   c_names.concat(get_nested_complex_types(obj, defined))  }        
      defined.concat(c_names)
    end
    defined.sort_by { |hash| hash[:class].downcase }.uniq unless defined.blank?
  end


  def get_complex_types(map)
    defined = []
    map.each do |operation, formats|
      (formats[:in] + formats[:out]).each do |p|
        defined.concat(get_nested_complex_types(p, defined))
      end
    end
    defined.sort_by { |hash| hash[:class].downcase }.uniq unless defined.blank?
  end

  def get_fault_types_names(map)
    defined = map.select{|operation, formats| !formats[:raises].blank? }
    defined = defined.collect {|operation, formats|  formats[:raises].is_a?(Array)  ? formats[:raises] : [formats[:raises]] }.flatten.select { |x| x.class.ancestors.include?(WashOut::SOAPError) }  unless defined.blank?
    defined.map{|item| item.class.to_s }.sort_by { |name| name.downcase }.uniq unless defined.blank?
  end

  def get_soap_action_names(map)
    map.map{|operation, formats| operation.to_s }.sort_by { |name| name.downcase }.uniq unless map.blank?
  end


  def create_html_complex_types(xml, types)
    types.each  { |hash| create_complex_type_html(xml, hash[:obj], hash[:class], hash[:ancestors]) }
  end



  def create_complex_type_html(xml, param, class_name, ancestors)
    unless param.blank?
      xml.a( "name" => "#{class_name}")  { }
      xml.h3  { |pre| pre << "#{class_name} #{ancestors.blank? ? "" : "<small>(extends <a href='##{ancestors[0].to_s.classify}'>#{ancestors[0].to_s.classify}</a>)</small>" } " }

      if param.is_a?(WashOut::Param)
        xml.ul("class" => "pre") {
          
          param.map.each do |element|
            element.type = "string" if element.type == "text"
            # raise YAML::dump(element) if class_name.include?("ype") and element.name == "members"
            xml.li { |pre|
              if WashoutBuilder::Type::BASIC_TYPES.include?(element.type)
                pre << "<span class='blue'>#{element.type}</span>&nbsp;<span class='bold'>#{element.name}</span>"
              else
                complex_class = get_complex_class_name(element)
                unless  complex_class.nil?
                  if  element.multiplied == false
                    pre << "<a href='##{complex_class}'><span class='lightBlue'>#{complex_class}</span></a>&nbsp;<span class='bold'>#{element.name}</span>"
                  else
                    pre << "<a href='##{complex_class}'><span class='lightBlue'>Array of #{complex_class}</span></a>&nbsp;<span class='bold'>#{element.name}</span>"
                  end
                end
              end
            }

          end

        }

      end
    end
  end

  def create_html_fault_types_details(xml, map)
    defined = map.select{|operation, formats| !formats[:raises].blank? }
    unless defined.blank?
      defined =  defined.collect {|operation, formats|  formats[:raises].is_a?(Array)  ? formats[:raises] : [formats[:raises]] }.flatten.sort_by { |item| item.class.to_s.downcase }.uniq
      defined.each {  |fault| create_html_fault_type(xml, fault) }  
    end
  end

  def create_html_fault_type(xml, param)
    if param.class.ancestors.include?(WashOut::SOAPError) 
      xml.h3 "#{param.class}"
      xml.a("name" => "#{param.class}") {}
      xml.ul("class" => "pre") {
      
      
        param.class.accessible_attributes.each do |attribute|
          if attribute!="code" && attribute != "message"  && attribute!= 'backtrace'
            attribute_class = param.send(attribute).class.name.downcase
            xml.li { |pre|
              if WashoutBuilder::Type::BASIC_TYPES.include?(attribute_class) || attribute_class == "nilclass" 
                pre << "<span class='blue'>#{attribute_class == "nilclass" ? "string" : attribute_class }</span>&nbsp;<span class='bold'>#{attribute}</span>"
              else
                pre << "<a href='##{attribute.class.name}'><span class='lightBlue'>#{attribute.class.name}</span></a>&nbsp;<span class='bold'>#{attribute}</span>"
              end
            }
          end
        end
        xml.li { |pre| pre << "<span class='blue'>integer</span>&nbsp;<span class='bold'>code</span>" }
        xml.li { |pre| pre << "<span class='blue'>string</span>&nbsp;<span class='bold'>message</span>" }
        xml.li { |pre| pre << "<span class='blue'>string</span>&nbsp;<span class='bold'>backtrace</span>" }
      }
    end
  end

  def create_html_public_methods(xml, map)
    unless map.blank?
      map =map.sort_by { |operation, formats| operation.downcase }.uniq
      map.each {  |operation, formats| create_html_public_method(xml, operation, formats) }
    end
  end



  def create_html_public_method(xml, operation, formats)
    # raise YAML::dump(formats[:in])
    xml.h3 "#{operation}"
    xml.a("name" => "#{operation}") {}


    xml.p("class" => "pre"){ |pre|
      if !formats[:out].nil?
        if WashoutBuilder::Type::BASIC_TYPES.include?(formats[:out][0].type)
          xml.span("class" => "blue") { |y| y<<  "#{formats[:out][0].type}" }
        else
          xml.a("href" => "##{formats[:out][0].type}") { |xml| xml.span("class" => "lightBlue") { |y| y<<"#{formats[:out][0].type}" } }
        end
      else
        pre << "void"
      end

      xml.span("class" => "bold") {|y|  y << "#{operation} (" }
      mlen = formats[:in].size
      xml.br if mlen > 1
      spacer = "&nbsp;&nbsp;&nbsp;&nbsp;"
      if mlen > 0
        j=0
        while j<mlen
          param = formats[:in][j]
          complex_class = get_complex_class_name(param)  
          use_spacer =  mlen > 1 ? true : false
          if WashoutBuilder::Type::BASIC_TYPES.include?(param.type)
            pre << "#{use_spacer ? spacer: ''}<span class='blue'>#{param.type}</span>&nbsp;<span class='bold'>#{param.name}</span>"
          else
            unless complex_class.nil?
              if  param.multiplied == false
                pre << "#{use_spacer ? spacer: ''}<a href='##{complex_class}'><span class='lightBlue'>#{complex_class}</span></a>&nbsp;<span class='bold'>#{param.name}</span>"
              else
                pre << "#{use_spacer ? spacer: ''}<a href='##{complex_class}'><span class='lightBlue'>Array of #{complex_class}</span></a>&nbsp;<span class='bold'>#{param.name}</span>"
              end
            end
          end
          if j< (mlen-1)
            xml.span ", "
          end
          if mlen > 1
            xml.br
          end
          if (j+1) == mlen
            xml.span("class" => "bold") {|y|  y << ")" }
          end
          j+=1
        end

      end



    }
    xml.p "#{formats[:description]}" if !formats[:description].blank?
    xml.p "Parameters:"

    xml.ul {
      j=0
      mlen = formats[:in].size
      while j<mlen
        param = formats[:in][j]
        complex_class = get_complex_class_name(param)  
        xml.li("class" => "pre") { |pre|
          if WashoutBuilder::Type::BASIC_TYPES.include?(param.type)
            pre << "<span class='blue'>#{param.type}</span>&nbsp;<span class='bold'>#{param.name}</span>"
          else
            unless complex_class.nil?
              if  param.multiplied == false
                pre << "<a href='##{complex_class}'><span class='lightBlue'>#{complex_class}</span></a>&nbsp;<span class='bold'>#{param.name}</span>"
              else
                pre << "<a href='##{complex_class}'><span class='lightBlue'>Array of #{complex_class}</span></a>&nbsp;<span class='bold'>#{param.name}</span>"
              end
            end
          end
        }
        j+=1
      end

    }

    xml.p "Return value:"
    xml.ul {
      xml.li {
        if !formats[:out].nil?

          if WashoutBuilder::Type::BASIC_TYPES.include?(formats[:out][0].type)
            xml.span("class" => "pre") { |xml| xml.span("class" => "blue") { |sp| sp << "#{formats[:out][0].type}" } }
          else
            xml.span("class" => "pre") { xml.a("href" => "##{formats[:out][0].type}") { |xml| xml.span("class" => "lightBlue") { |y| y<<"#{formats[:out][0].type}" } } }
          end
        else
          xml.span("class" => "pre") { |sp| sp << "void" }
        end

      }
    }
    unless formats[:raises].blank?
      faults = formats[:raises]
      faults = [formats[:raises]] if !faults.is_a?(Array)
      
      faults = faults.select { |x| x.class.ancestors.include?(WashOut::SOAPError) }
      unless faults.blank?
        xml.p "Exceptions:"
        xml.ul {
          faults.each do |p|
            xml.li("class" => "pre"){ |y| y<< "<a href='##{p.class.to_s}'><span class='lightBlue'> #{p.class.to_s}</span></a>" }
          end
        }
      end
    end
  end

end
