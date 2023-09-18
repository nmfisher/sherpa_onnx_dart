#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_sherpa_onnx.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_sherpa_onnx'
  s.version          = '0.0.1'
  s.summary          = 'A new flutter plugin project.'
  s.description      = <<-DESC
A new flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*.*', 'include/*.h', 'include/sherpa-onnx/c-api/c-api.h'
  s.public_header_files = 'include/**/*.h'
  s.static_framework = true
  s.dependency 'Flutter'
  s.platform = :ios, '9.0'

  s.pod_target_xcconfig = { 
    'DEFINES_MODULE' => 'YES', 
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',     
    "FRAMEWORK_SEARCH_PATHS" => '"${PODS_ROOT}/../.symlinks/plugins/flutter_onnx/ios/lib"',
    'USER_HEADER_SEARCH_PATHS' => '"${PODS_ROOT}/../.symlinks/plugins/flutter_sherpa_onnx/ios/include" "$(inherited)"',
    'OTHER_LDFLAGS' => '-v -framework Accelerate -framework onnxruntime $(inherited) "-L${PODS_ROOT}/../.symlinks/plugins/flutter_sherpa_onnx/ios/lib" -l:sherpa-onnx.a'
  }
  s.user_target_xcconfig = { 
    'DEFINES_MODULE' => 'YES', 
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',     
    "FRAMEWORK_SEARCH_PATHS" => '"${PODS_ROOT}/../.symlinks/plugins/flutter_onnx/ios/lib"',
    'USER_HEADER_SEARCH_PATHS' => '"${PODS_ROOT}/../.symlinks/plugins/flutter_sherpa_onnx/ios/include" "$(inherited)"',
    'OTHER_LDFLAGS' => '-v -framework Accelerate $(inherited) -framework onnxruntime "-L${PODS_ROOT}/../.symlinks/plugins/flutter_sherpa_onnx/ios/lib" -lsherpa-onnx'
  }
 
  s.swift_version = '5.0'


end
