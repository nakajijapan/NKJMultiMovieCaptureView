#
# Be sure to run `pod lib lint NAME.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name                  = "NKJMultiMovieCaptureView"
  s.version               = "0.1.1"
  s.summary               = "NKJMultiMovieCaptureView can store multiple videos while touching the screen"
  s.homepage              = "http://github.com/nakajijapan"
  s.license               = 'MIT'
  s.author                = { "nakajijapan" => "pp.kupepo.gattyanmo@gmail.com" }
  s.source                = { :git => "https://github.com/nakajijapan/NKJMultiMovieCaptureView.git", :tag => s.version.to_s }
  s.social_media_url      = 'https://twitter.com/nakajijapan'
  s.platform              = :ios, '7.0'
  s.ios.deployment_target = '5.0'
  s.requires_arc          = true
  s.source_files          = 'Classes'
  s.frameworks            = 'AVFoundation', 'CoreMedia'
end
