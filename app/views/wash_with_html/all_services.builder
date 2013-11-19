xml.instruct!
xml.declare! :DOCTYPE, :html, :PUBLIC, "-//W3C//DTD XHTML 1.0 Strict//EN", "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"

xml.html( "xmlns" => "http://www.w3.org/1999/xhtml" ) {

  xml.head {

    xml.title "#{@service} interface description"

    xml.style( "type"=>"text/css" ,"media" => "all" ) { xml.text! "
    body{font-family:Calibri,Arial;background-color:#fefefe;}
    .pre{font-family:Courier;}
    .normal{font-family:Calibri,Arial;}
    .bold{font-weight:bold;}
    h1,h2,h3{font-family:Verdana,Times;}
    h1{border-bottom:1px solid gray;}
    h2{border-bottom:1px solid silver;}
    h3{border-bottom:1px dashed silver;}
    a{text-decoration:none;}
    a:hover{text-decoration:underline;}
    .blue{color:#3400FF;}
    .lightBlue{color:#5491AF;}
      "

    }

    xml.style( "type"=>"text/css", "media" => "print" ) { xml.text! "
    .noprint{display:none;}
      "

    }


  }


  xml.body {

    @services.each do |service|
      xml.h1 "#{service[:service_name]} Soap Webservice"
      xml.p {|pre| pre << "Endpoint URI: &nbsp;<a href='#{service[:endpoint_url]}'>#{service[:endpoint_url]}</a>" }
      xml.p {|pre|  pre << "WSDL URI: &nbsp;<a href='#{service[:namespace_url]}'>#{service[:namespace_url]}</a>" }
    end

  }


}