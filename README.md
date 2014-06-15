# NKJMultiMovieCaptureView

[![Version](https://img.shields.io/cocoapods/v/NKJMultiMovieCaptureView.svg?style=flat)](http://cocoadocs.org/docsets/NKJMultiMovieCaptureView)
[![License](https://img.shields.io/cocoapods/l/NKJMultiMovieCaptureView.svg?style=flat)](http://cocoadocs.org/docsets/NKJMultiMovieCaptureView)
[![Platform](https://img.shields.io/cocoapods/p/NKJMultiMovieCaptureView.svg?style=flat)](http://cocoadocs.org/docsets/NKJMultiMovieCaptureView)

NKJMultiMovieCaptureView is CaptureSessionView for saving videos while touching the screen.

## Requirements

NKJMultiMovieCaptureView higher requires Xcode 5, targeting either iOS 7.1 and above, or Mac OS 10.9 OS X Mavericks and above.

* AVFoundation.framework
* CoreMedia.framework

## Installation

### CocoaPods

```
pod "NKJMultiMovieCaptureView"
```

## Usage

```obj-c
NKJMultiMovieCaptureView *previewView = [[NKJMultiMovieCaptureView alloc] initWithFrame:CGRectMake(0, 20, 320, 320)];
[self.view addSubview:self.previewView];
```

## Author

nakajijapan, pp.kupepo.gattyanmo@gmail.com

## License

NKJMultiMovieCaptureView is available under the MIT license. See the LICENSE file for more info.

