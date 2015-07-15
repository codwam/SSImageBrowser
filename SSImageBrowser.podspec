#
# Be sure to run `pod lib lint SSImageBrowser.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "SSImageBrowser"
  s.version          = "0.1.2"
  s.summary          = "IDMPhotoBrowser in Swift"
  s.description      = <<-DESC
                       IDMPhotoBrowser in Swift
                       Photo Browser / Viewer inspired by Facebook's and Tweetbot's with ARC support, swipe-to-dismiss, image progress and more
                       DESC
  s.homepage         = "https://github.com/CodeEagle/SSImageBrowser"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "CodeEagle" => "stasura@hotmail.com" }
  s.source           = { :git => "https://github.com/CodeEagle/SSImageBrowser.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/_SelfStudio'

  s.platform     = :ios, '8.0'
  s.requires_arc = true
  s.resources     =  'Source/IDMPhotoBrowser.bundle', 'Source/IDMPBLocalizations.bundle'
  s.source_files = 'Source/*.swift'
  s.frameworks = 'MessageUI', 'QuartzCore', 'SystemConfiguration', 'MobileCoreServices', 'Security'
  s.dependency       'pop'
  s.dependency       'DACircularProgress'
  s.dependency       'SDWebImage'
end