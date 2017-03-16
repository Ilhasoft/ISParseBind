Pod::Spec.new do |s|
  s.name         = "ISParseBind"
  s.version      = "1.0.0"
  s.summary      = "Use Interface Builder for bind components with parse server."
  s.description  = <<-DESC
		   With ISParseBind you can save, update, and query PFObjects using the power of Xcode Interface Builder resources.  
                   DESC

  s.homepage     = "http://www.ilhasoft.com.br"
  # s.screenshots  = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"
  s.license      = "MIT"
  s.author             = { "Daniel Amaral" => "daniel@ilhasoft.com.br" }
  s.social_media_url   = "http://twitter.com/danielamarall"
  s.ios.deployment_target = '9.0'
  s.source       = { :git => "https://github.com/Ilhasoft/ISParseBind.git", :tag => s.version }
  s.source_files  = "Classes", "ISParseBind/Classes/**/*"
  #s.exclude_files = "Classes/Exclude"
  #s.public_header_files = 'Pod/Classes/**/*.h'
  s.dependency "Parse"
  s.dependency "Kingfisher"

end
