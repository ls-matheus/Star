Pod::Spec.new do |s|
  s.name             = 'star_voice'
  s.version          = '0.0.1'
  s.summary          = 'Star native voice handling package'
  s.description      = 'Star native voice handling package'
  s.homepage         = 'https://github.com/starapp'
  s.license          = { :type => 'AGPL-3.0' }
  s.author           = 'Star'
  s.source           = { :path => '.' }
  s.source_files     = 'star_voice/Sources/star_voice/**/*.swift'
  s.platform         = :osx, '12.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version    = '5.0'

  s.dependency 'FlutterMacOS'
end
