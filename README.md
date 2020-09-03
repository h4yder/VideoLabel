# VideoLabel

![VideoLabel text with blue particles in the text](Images/VideoLabel.gif)

iOS text with video as text background.

## Features

* Supports local and remote videos.
* Fully accessible with support for Dynamic Text and Voice Over.
* `text`, `attributedText`, `font`, `url` and `alignment` are configurable.
* Supports multiple labels with different videos in the same view.

![Two video labels with different videos](Images/BlueWater.gif)


## Installation 

### Swift Package Manager
Add the package using Xcode by going to:  

File > Swift Packages > Add Package Dependency: https://github.com/h4yder/VideoLabel

### Manually
Drag VideoLabel.swift into your project, its self-contained.

## How to use

Just import the module and add a view.


    import VideoLabel

    class ViewController: UIViewController {
        func viewDidLoad() {
            super.viewDidLoad()

            let url = Bundle.main.url(forResource: "Video", withExtension: "mov")!
            let label = VideoLabel(text: "Hello World!", url: url)
            label.font = UIFont.systemFont(ofSize: 60)

            view.addSubview(label)
        }
    }

Or using an `NSAttributedString`.
            
            let attribs: [NSAttributedString.Key: Any] = [
                /* a dictionary of text attributes like kern, font etc.. */
                ]
            let attributedText = NSAttributedString(string: "Hello World!", attributes: attribs)

            let url = Bundle.main.url(forResource: "Video", withExtension: "mov")!
            let label = VideoLabel(attributedText: attributedText, url: url)

## More
For more information about how it works, you can read about it [here](https://medium.com/@hayderado/bring-your-titles-to-life-in-ios-d427bb3311b).
