#
# Be sure to run `pod lib lint NKJMultiMovieCaptureView.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name                  = "NKJMultiMovieCaptureView"
  s.version               = "1.0.0"
  s.summary               = "NKJMultiMovieCaptureView can store multiple videos while touching the screen"
  s.homepage              = "http://github.com/nakajijapan"
  s.license               = 'MIT'
  s.author                = { "nakajijapan" => "pp.kupepo.gattyanmo@gmail.com" }
  s.source                = { :git => "https://github.com/nakajijapan/NKJMultiMovieCaptureView.git", :tag => s.version.to_s }
  s.social_media_url      = 'https://twitter.com/nakajijapan'

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'NKJMultiMovieCaptureView' => ['Pod/Assets/*.png']
  }

  s.frameworks = 'AVFoundation', 'CoreMedia'
end
