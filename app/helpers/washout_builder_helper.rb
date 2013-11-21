module WashoutBuilderHelper
  include WashOutHelper

  def get_complex_class_name(p, defined = [])
    complex_class = nil
    if !p.source_class_name.nil?  # it is a class and has ancestor WashoutBuilder::Type
      complex_class=  p.source_class_name
    elsif p.struct? && p.classified?    # it is a class
      complex_class = p.source_class
    elsif p.struct? 
      complex_class = p.name.classify
    end
    if !complex_class.nil? && !defined.blank?
      timestamp = Time.now.to_i

      found = false
      defined.each do |hash|
        found = true if hash[:class] == complex_class
      end
      if found == true && p.struct?  &&  !p.classified?
                 
      raise RuntimeError, "Duplicate use of `#{p.basic_type}` type name. Consider using classified types."
        # found a nested hash 
        #complex_class = complex_class+timestamp.to_s
       # p.timestamp = timestamp.to_s
      end
    elsif !complex_class.nil? && defined.blank? and p.timestamp
      complex_class = complex_class+p.timestamp
    end

    return complex_class
  end


  def get_nested_complex_types(param, defined)
    defined = [] if defined.blank?
    complex_class = get_complex_class_name(param, defined)
    defined << {:class =>complex_class, :obj => param} unless complex_class.nil?
    if param_is_complex?(param)
      c_names = []
      param.map.each do |obj|
        nested = get_nested_complex_types(obj, defined)
        nested.each  do |hash|
          c_names << hash
        end
      end
      defined.concat(c_names)
    end
    defined.sort_by { |hash| hash[:class].downcase }.uniq unless defined.blank?
  end


  def get_complex_types(map)
    defined = []
    map.each do |operation, formats|
      (formats[:input] + formats[:output]).each do |p|
        nested = get_nested_complex_types(p, defined)
        nested.each  do |hash|
          defined << hash
        end
      end
    end
    defined <<  {:class =>"ValidationErrors", :obj => nil} unless get_fault_types_names(map).blank?
  defined.sort_by { |hash| hash[:class].downcase }.uniq unless defined.blank?
  end

  def get_fault_types_names(map)
    defined = []
    map.each do |operation, formats|
      faults = formats[:raises]
      unless faults.blank?
        faults = [formats[:raises]] if !faults.is_a?(Array)
        faults.each do |p|
          defined << p.to_s.classify
        end
      end
    end
    defined.sort_by { |name| name.downcase }.uniq unless defined.blank?
  end

  def get_soap_action_names(map)
    defined = []
    unless map.blank?
      map.each do |operation, formats|
        defined << operation.to_s
      end
    end
    defined.sort_by { |name| name.downcase }.uniq unless defined.blank?
  end


  def param_is_complex?(p)
    !p.source_class_name.nil? || (p.type == "struct" && !p.source_class.blank?) || p.type =="struct" # it is a class and has ancestor WashoutBuilder::Type
  end

  def create_html_complex_type_validation_errors(xml)
    xml.a( "name" => "ValidationErrors")  { }
    xml.h3 "ValidationErrors"

    xml.ul("class" => "pre") {
      xml.li { |pre| pre << "<span class='blue'>string</span>&nbsp;<span class='bold'>related</span>" }
      xml.li { |pre| pre << "<span class='blue'>string</span>&nbsp;<span class='bold'>message</span>" }
      xml.li { |pre| pre << "<span class='blue'>Array of string</span>&nbsp;<span class='bold'>arguments</span>" }
    }
  end



  def create_html_complex_types(xml, types)
    types.each do |hash|
      create_complex_type_html(xml, hash[:obj], hash[:class])
    end
  end



  def create_complex_type_html(xml, param, class_name)
    unless param.blank?
      xml.a( "name" => "#{class_name}")  { }
      xml.h3 "#{class_name}"

      if param.is_a?(WashoutBuilder::Param)
        xml.ul("class" => "pre") {

          param.map.each do |element|
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
    defined = []
    unless map.blank?
     map =  map.sort_by { |operation, formats| formats[:raises].to_s.downcase }.uniq
      map.each do |operation, formats|
        faults = formats[:raises]
        unless faults.blank?
          faults = [formats[:raises]] if !faults.is_a?(Array)
          faults.each do |p|
            defined << p
          end
        end
      end
    end
    unless defined.blank?
   defined =  defined.sort_by { |name| name.to_s.downcase }.uniq
     defined.each do |fault|
       create_html_fault_type(xml, fault)
     end
    end
  end

  def create_html_fault_type(xml, param)
    xml.h3 "#{param}"
    xml.a("name" => "#{param}") {}
    xml.ul("class" => "pre") {
      if param.ancestors.include?(WashoutBuilder::SoapFault)

        param.accessible_attributes.each do |attribute|
          xml.li { |pre|
            if WashoutBuilder::Type::BASIC_TYPES.include?(attribute.class.name.downcase) && attribute != "errors"
              pre << "<span class='blue'>#{attribute.class.name.downcase}</span>&nbsp;<span class='bold'>#{attribute}</span>"
            elsif attribute == "errors"
              pre << "<a href='#ValidationErrors'><span class='lightBlue'>Array of ValidationErrors</span></a>&nbsp;<span class='bold'>#{attribute}</span>"
            else
              pre << "<a href='##{attribute.class.name}'><span class='lightBlue'>#{attribute.class.name}</span></a>&nbsp;<span class='bold'>#{attribute}</span>"
            end
          }
        end
        xml.li { |pre| pre << "<span class='blue'>string</span>&nbsp;<span class='bold'>backtrace</span>" }
      end
    }
  end

  def create_html_public_methods(xml, map)
    unless map.blank?
      map =map.sort_by { |operation, formats| operation.downcase }.uniq

      map.each do |operation, formats|
        create_html_public_method(xml, operation, formats)
      end
    end
  end



  def create_html_public_method(xml, operation, formats)
    # raise YAML::dump(formats[:input])
    xml.h3 "#{operation}"
    xml.a("name" => "#{operation}") {}


    xml.p("class" => "pre"){ |pre|
      if !formats[:output].nil?
        if WashoutBuilder::Type::BASIC_TYPES.include?(formats[:output][0].type)
          xml.span("class" => "blue") { |y| y<<  "#{formats[:output][0].type}" }
        else
          xml.a("href" => "##{formats[:output][0].type}") { |xml| xml.span("class" => "lightBlue") { |y| y<<"#{formats[:output][0].type}" } }
        end
      else
        pre << "void"
      end

      xml.span("class" => "bold") {|y|  y << "#{operation} (" }
      mlen = formats[:input].size
      xml.br if mlen > 1
      spacer = "&nbsp;&nbsp;&nbsp;&nbsp;"
      if mlen > 0
        j=0
        while j<mlen
          param = formats[:input][j]
          use_spacer =  mlen > 1 ? true : false
          if WashoutBuilder::Type::BASIC_TYPES.include?(param.type)
            pre << "#{use_spacer ? spacer: ''}<span class='blue'>#{param.type}</span>&nbsp;<span class='bold'>#{param.name}</span>"
          else
            complex_class = get_complex_class_name(param)
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
      mlen = formats[:input].size
      while j<mlen
        param = formats[:input][j]
        xml.li("class" => "pre") { |pre|
          if WashoutBuilder::Type::BASIC_TYPES.include?(param.type)
            pre << "<span class='blue'>#{param.type}</span>&nbsp;<span class='bold'>#{param.name}</span>"
          else
            complex_class = get_complex_class_name(param)
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
        if !formats[:output].nil?

          if WashoutBuilder::Type::BASIC_TYPES.include?(formats[:output][0].type)
            xml.span("class" => "pre") { |xml| xml.span("class" => "blue") { |sp| sp << "#{formats[:output][0].type}" } }
          else
            xml.span("class" => "pre") { xml.a("href" => "##{formats[:output][0].type}") { |xml| xml.span("class" => "lightBlue") { |y| y<<"#{formats[:output][0].type}" } } }
          end
        else
          xml.span("class" => "pre") { |sp| sp << "void" }
        end

      }
    }
    unless formats[:raises].blank?
      faults = formats[:raises]
      faults = [formats[:raises]] if !faults.is_a?(Array)

      xml.p "Exceptions:"
      xml.ul {
        faults.each do |p|
          xml.li("class" => "pre"){ |y| y<< "<a href='##{p.to_s.classify}'><span class='lightBlue'> #{p.to_s.classify}</span></a>" }
        end
      }
    end
  end

end
