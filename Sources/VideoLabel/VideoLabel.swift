//
//  VideoLabel.swift
//  VideoLabelDemo
//
//  Created by Hayder Al-Husseini on 27/08/2020.
//  Copyright © 2020 kodeba•se ltd.
//
//  See LICENSE.md for licensing information.
//

import UIKit
import AVKit

public class VideoLabel: UIView {
    private struct Constants {
        static let defaultFont = UIFont.preferredFont(forTextStyle: .largeTitle)
        static let maximumFontSizeDelta: CGFloat = 35.0
        static let defaultAlignment: NSTextAlignment = .left
    }
    /**
     The current text that is displayed by the view.
    */
    @IBInspectable public var text: String? {
        didSet {
            updateVideoMask()
        }
    }
    
    /**
     The current styled text that is displayed by the view.
    */
    public var attributedText: NSAttributedString? {
        didSet {
            updateVideoMask()
        }
    }
    /**
    The url of the video that will play over the text. Both local and remote videos are supported.
     */
    public var url: URL?

    /**
     The font that is used when initialised with `init(text:,url)`.
     
     The default font is `UIFont.preferredFont(forTextStyle: .largeTitle)`
     */
    public var font: UIFont? {
        didSet {
            updateVideoMask()
        }
    }
    
    /**
       The text alignment to use when initialised with `init(text:,url)`.
     
       The default value is .left
    */
    public var alignment: NSTextAlignment = .left
        
    private var playerLayer: AVPlayerLayer?
            
    private static func accessibilityFontSizeDelta() -> CGFloat {
        let contentSizeCategory: UIContentSizeCategory = UIApplication.shared.preferredContentSizeCategory
        // Based on Title 3 Row in the table at
        // https://developer.apple.com/design/human-interface-guidelines/ios/visual-design/typography/
        switch contentSizeCategory {
        case .extraSmall:
            return -3.0
            
        case .small:
            return -2.0
            
        case .medium:
            return -1.0
            
        case .large:
            return 0.0
            
        case .extraLarge:
            return 2.0
            
        case .extraExtraLarge:
            return 4.0
            
        case .extraExtraExtraLarge:
            return 6.0
            
        // Accessibility sizes
        case .accessibilityMedium:
            return 11.0
            
        case .accessibilityLarge:
            return 17.0
            
        case .accessibilityExtraLarge:
            return 23.0
            
        case .accessibilityExtraExtraLarge:
            return 29.0
            
        case .accessibilityExtraExtraExtraLarge:
            return Constants.maximumFontSizeDelta
            
        default:
            return 0
        }
    }
    
    // MARK: - Life cycle
    
    /**
     Create a text view that has a video as a background to the text.
     - parameters:
        - text: The text that will be displayed by the label.
        -  url: The url of the video that will play over the text. Both local and remote videos are supported.
     
      The value of text will also set the value of `attributedText` but without any formatting.
     */
    public init(text: String, url: URL) {
            self.text = text
            self.url = url
            super.init(frame: .zero)
    }

    /**
     Create a text view that has a video as a background to the styled text.
     - parameters:
        - attributedText: The styled text that will be displayed by the label.
        -  url: The url of the video that will play over the text. Both local and remote videos are supported.
     
     The value of styled text will also set `text` with the same string value. This is also the recommended approach to settings the label.
     */
    public init(attributedText text: NSAttributedString, url: URL) {
            self.attributedText = text
            self.url = url
            super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
        
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        setupBackgroundVideoIfNeeded()
        updateVideoMask()
    }
    
    public override var intrinsicContentSize: CGSize {
        guard let attributedString = maskAttributedText() else {
            return .zero
        }
        
        let bitmapSpaceSize = attributedString.boundingRect(with: UIView.layoutFittingExpandedSize, options: .usesFontLeading, context: nil).size
        return CGSize(width: ceil(bitmapSpaceSize.width / Bitmap.contentScale), height: ceil(bitmapSpaceSize.height / Bitmap.contentScale))
    }
    
    // MARK: - Logic
    
    /**
    Create a player layer if one doesn't exists is set it up.
     
     The video `url` provided when initializing the view will be used.
    */
    private func setupBackgroundVideoIfNeeded() {
        guard playerLayer == nil, let url = url else {
            return
        }
        
        let player = AVPlayer(url: url)
        
        if let playerItem = player.currentItem {
            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: playerItem, queue: nil) { [weak self] notification in
                let currentItem = notification.object as? AVPlayerItem
                currentItem?.seek(to: .zero, completionHandler: nil)
                
                if let player = self?.playerLayer?.player,
                    player.currentItem == currentItem {
                    player.play()
                }
            }
        }
        
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.frame = CGRect(x: 0.0, y: 0.0,
                                   width: frame.size.width,
                                   height: frame.size.height)
        
        layer.addSublayer(playerLayer)
        
        self.playerLayer = playerLayer
        
        player.volume = 0
        player.play()
    }
    
    /**
    Create a mask for the video.
     
     The mask is generated from the `text` or `attributedText` property provided when initializing the view.
    */
    private func updateVideoMask() {
        guard let playerLayer = playerLayer,
            frame.size != .zero else {
            return
        }
        
        let textMask = generateTextMask()
        let maskLayer = CALayer()
        let layerFrame = CGRect(x: 0.0, y: 0.0, width: frame.size.width, height: frame.size.height)
        
        maskLayer.contents = textMask
        playerLayer.mask = maskLayer
        
        maskLayer.frame = layerFrame
        playerLayer.frame = layerFrame
        
        updateAccessibility()
    }
    
    /**
    Creates the contents of the mask layer.
     
     The mask is generated from the `text` or `attributedText` property provided when initializing the view. If `text` is used, `font` and `alignment` are used to configure the text's styling.
     
     If The text doesn't fit inside the view, it will log an error to the console.
     
     - returns:
     A `CGImage` if the mask was created successfully.

    */
    private func generateTextMask() -> CGImage? {
        guard frame.size.width != 0.0,
            frame.size.height != 0.0,
            let attributedString = maskAttributedText() else {
            return nil
        }

        let bitmap = Bitmap(width: frame.size.width, height: frame.size.height)
    
        bitmap.context.clear(bitmap.bounds)
       
        let framesetter = CTFramesetterCreateWithAttributedString(attributedString)
        let range = CFRange(location: 0, length: attributedString.length)
        var effectiveRange: CFRange = .init(location: 0, length: 0)
        let suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, range, nil, bitmap.bounds.size, &effectiveRange)
        
        if effectiveRange.length < range.length {
            print("VideoLabel ERROR: The view's frame is too small to display the full text.")
        }
        
        let path = CGMutablePath()
        let bitmapBounds = bitmap.bounds
        
        let textRect: CGRect
        
        let alignment = textAlignment(for: attributedString)
        
        switch alignment {
        case .left, .natural:
            textRect = CGRect(x: 0.0,
                              y: (bitmapBounds.size.height - suggestedSize.height) * 0.5,
                              width: suggestedSize.width,
                              height: suggestedSize.height)
            
        case .right:
            textRect = CGRect(x: bitmapBounds.size.width - suggestedSize.width,
                              y: (bitmapBounds.size.height - suggestedSize.height) * 0.5,
                              width: suggestedSize.width,
                              height: suggestedSize.height)
            
        case .justified, .center:
            textRect = CGRect(x: (bitmapBounds.size.width - suggestedSize.width) * 0.5,
                              y: (bitmapBounds.size.height - suggestedSize.height) * 0.5,
                              width: suggestedSize.width,
                              height: suggestedSize.height)
        @unknown default:
            textRect = CGRect(x: (bitmapBounds.size.width - suggestedSize.width) * 0.5,
                              y: (bitmapBounds.size.height - suggestedSize.height) * 0.5,
                              width: suggestedSize.width,
                              height: suggestedSize.height)
        }
        
        path.addRect(textRect)
        let textRectInViewSpace = CGRect(x: textRect.origin.x / Bitmap.contentScale,
                                         y: textRect.origin.y / Bitmap.contentScale,
                                         width: textRect.size.width / Bitmap.contentScale,
                                         height: textRect.size.height / Bitmap.contentScale)
        let textRectInScreenSpace = UIAccessibility.convertToScreenCoordinates(textRectInViewSpace, in: self)
        accessibilityFrame = textRectInScreenSpace
        
        let ctFrame = CTFramesetterCreateFrame(framesetter, CFRange(location: 0, length: CFIndex(attributedString.length)), path, nil)

        CTFrameDraw(ctFrame, bitmap.context)
        
        return bitmap.cgImage
    }
    
    private func textAlignment(for attributedString: NSAttributedString) -> NSTextAlignment {
        guard let paragraphStyle = attributedString.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle else {
            return Constants.defaultAlignment
        }
        
        return paragraphStyle.alignment
    }
    
    private func maskAttributedText() -> NSAttributedString? {
        guard let text = text else {
            return accessibleAttributedString()
        }
        
        let textFont: UIFont
        
        if let font = self.font {
            textFont = font
        } else {
            textFont = Constants.defaultFont
        }
        
        // Get the amount we need to change our font size by for dynamicText
        let delta = VideoLabel.accessibilityFontSizeDelta()
        let bitmapScale = Bitmap.contentScale
        let accessibleFont = UIFont(descriptor: textFont.fontDescriptor,
                                    size: (textFont.pointSize + delta) * bitmapScale)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        
        let attribString = NSAttributedString(string: text,
                                              attributes: [.font: accessibleFont,
                                                           .foregroundColor: UIColor.black.cgColor,
                                                           .paragraphStyle: paragraphStyle])
        return attribString
    }
    
    private func accessibleAttributedString() -> NSAttributedString? {
        guard let source = attributedText else {
            return nil
        }
        let sourceFont: UIFont
        // Get the attributed string's font
        if let attributedStringFont = source.attribute(.font, at: 0, effectiveRange: nil) as? UIFont {
            sourceFont = attributedStringFont
        } else {
            sourceFont = UIFont.preferredFont(forTextStyle: .largeTitle)
        }
        
        // Get the amount we need to change our font size by for dynamicText
        let delta = VideoLabel.accessibilityFontSizeDelta()
        
        let attributedString = NSMutableAttributedString(attributedString: source)
        
        let bitmapScale = Bitmap.contentScale
        let accessibleFont = UIFont(descriptor: sourceFont.fontDescriptor,
                                    size: (sourceFont.pointSize + delta) * bitmapScale)
        
        let attributes: [NSAttributedString.Key: Any] = [.font: accessibleFont,
                                                         .foregroundColor: UIColor.black.cgColor]
        
        attributedString.addAttributes(attributes, range: NSRange(location: 0, length: source.length))
        
        return attributedString
    }
    
    // MARK: - Accessibility
    private func updateAccessibility() {
        isAccessibilityElement = true
        
        if let text = text {
            accessibilityLabel = text
        } else if let attributedText = attributedText {
            accessibilityLabel = attributedText.string
        }
        accessibilityTraits = .staticText
    }
}


final class Bitmap {
    private(set) var context: CGContext
    
    init(width: CGFloat, height: CGFloat) {
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let scale = UIScreen.main.scale
        guard let context = CGContext(data: nil,
                                     width: Int(width * scale),
                                     height: Int(height * scale),
                                     bitsPerComponent: 8,
                                     bytesPerRow: 8 * Int(width * scale),
                                     space: CGColorSpaceCreateDeviceRGB(),
                                     bitmapInfo: bitmapInfo.rawValue) else {
                                        fatalError()
        }
        self.context = context
    }
    
    var cgImage: CGImage? {
        return context.makeImage()
    }
    
    var bounds: CGRect {
        return CGRect(x: 0.0, y: 0.0, width: CGFloat(context.width), height: CGFloat(context.height))
    }
    
    static var contentScale: CGFloat {
        return UIScreen.main.scale
    }
}
