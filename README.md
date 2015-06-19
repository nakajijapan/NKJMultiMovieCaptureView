# NKJMultiMovieCaptureView

[![Version](https://img.shields.io/cocoapods/v/NKJMultiMovieCaptureView.svg?style=flat)](http://cocoapods.org/pods/NKJMultiMovieCaptureView)
[![License](https://img.shields.io/cocoapods/l/NKJMultiMovieCaptureView.svg?style=flat)](http://cocoapods.org/pods/NKJMultiMovieCaptureView)
[![Platform](https://img.shields.io/cocoapods/p/NKJMultiMovieCaptureView.svg?style=flat)](http://cocoapods.org/pods/NKJMultiMovieCaptureView)

NKJMultiMovieCaptureView is CaptureSessionView for saving videos while touching the screen.


## Usage

```swift
NKJMultiMovieCaptureView *previewView = [[NKJMultiMovieCaptureView alloc] initWithFrame:CGRectMake(0, 20, 320, 320)];
[self.view addSubview:self.previewView];
```

## Requirements

NKJMultiMovieCaptureView higher requires Xcode 5, targeting either iOS 7.1 and above, or Mac OS 10.9 OS X Mavericks and above.

* AVFoundation.framework
* CoreMedia.framework

## Installation

NKJMultiMovieCaptureView is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "NKJMultiMovieCaptureView"
```

## Author

nakajijapan, pp.kupepo.gattyanmo@gmail.com

## License

NKJMultiMovieCaptureView is available under the MIT license. See the LICENSE file for more info.
