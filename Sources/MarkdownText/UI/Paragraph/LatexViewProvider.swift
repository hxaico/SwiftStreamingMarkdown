//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation
import iosMath
import MathExceptionCatcher
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - LatexAttachmentData Color Resolution

extension LatexAttachmentData {
  var resolvedTextColor: MDColor {
    let fallback = MDColor(Color.Theme.Foreground.Primary.Primary750)
    #if canImport(UIKit)
    guard let lightColor = UIColor(hex: lightTextColor),
          let darkColor = UIColor(hex: darkTextColor) else {
      return fallback
    }
    return UIColor { trait in
      trait.userInterfaceStyle == .dark ? darkColor : lightColor
    }
    #elseif canImport(AppKit)
    guard let lightColor = NSColor(hex: lightTextColor),
          let darkColor = NSColor(hex: darkTextColor) else {
      return fallback
    }
    return NSColor(name: nil) { appearance in
      let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
      return isDark ? darkColor : lightColor
    }
    #endif
  }
}

// MARK: - Latex View Provider

final class LatexViewProvider: NSTextAttachmentViewProvider {
  private let latex: String
  private let fontSize: CGFloat
  private let textColor: MDColor
  private static let jsonDecoder = JSONDecoder()

  private struct DecodedAttachment {
    var latex: String = ""
    var fontSize: CGFloat = Typography.base.mdFont.pointSize
    var textColor: MDColor = MDColor(Color.Theme.Foreground.Primary.Primary750)
  }

  #if canImport(UIKit)
  required override init(textAttachment attachment: NSTextAttachment,
                         parentView: UIView?,
                         textLayoutManager: NSTextLayoutManager?,
                         location: any NSTextLocation) {
    let decoded = Self.decode(attachment: attachment)
    (latex, fontSize, textColor) = (decoded.latex, decoded.fontSize, decoded.textColor)
    super.init(textAttachment: attachment, parentView: parentView,
               textLayoutManager: textLayoutManager, location: location)
    tracksTextAttachmentViewBounds = true
  }
  #elseif canImport(AppKit)
  required override init(textAttachment attachment: NSTextAttachment,
                         parentView: NSView?,
                         textLayoutManager: NSTextLayoutManager?,
                         location: any NSTextLocation) {
    let decoded = Self.decode(attachment: attachment)
    (latex, fontSize, textColor) = (decoded.latex, decoded.fontSize, decoded.textColor)
    super.init(textAttachment: attachment, parentView: parentView,
               textLayoutManager: textLayoutManager, location: location)
    tracksTextAttachmentViewBounds = true
  }
  #endif

  private static func decode(attachment: NSTextAttachment) -> DecodedAttachment {
    var result = DecodedAttachment()
    if let data = attachment.contents,
       let attachmentData = try? jsonDecoder.decode(LatexAttachmentData.self, from: data) {
      result.latex = attachmentData.latex
      result.fontSize = attachmentData.fontSize
      result.textColor = attachmentData.resolvedTextColor
    }
    return result
  }

  override func loadView() {
    MathRenderDiagnostics.logInlineMathIfInteresting(source: "loadView", latex: latex)
    let label = MTMathUILabel()
    var success = false
    try? MathExceptionCatcher.try {
      label.latex = self.latex
      success = label.mathList != nil
    }
    label.textColor = textColor
    label.displayErrorInline = false
    label.fontSize = fontSize
    label.setContentHuggingPriority(.defaultHigh, for: .vertical)

    if success {
      self.view = label
      return
    }

    #if canImport(UIKit)
    let fallbackLabel = UILabel()
    fallbackLabel.text = latex
    fallbackLabel.font = UIFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
    fallbackLabel.textColor = textColor
    self.view = fallbackLabel
    #elseif canImport(AppKit)
    let fallbackLabel = NSTextField(labelWithString: latex)
    fallbackLabel.isEditable = false
    fallbackLabel.isSelectable = false
    fallbackLabel.isBordered = false
    fallbackLabel.drawsBackground = false
    fallbackLabel.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
    fallbackLabel.textColor = textColor
    self.view = fallbackLabel
    #else
    self.view = label
    #endif
  }

  override func attachmentBounds(for attributes: [NSAttributedString.Key: Any],
                                 location: any NSTextLocation,
                                 textContainer: NSTextContainer?,
                                 proposedLineFragment: CGRect,
                                 position: CGPoint) -> CGRect {
    // TextKit may call attachmentBounds before loadView. Never rely on self.view here.
    let size = measuredAttachmentSize(proposedLineFragmentWidth: proposedLineFragment.width)
    let font = attributes[.font] as? MDFont ?? MDFont.systemFont(ofSize: fontSize)
    let yOffset = (font.xHeight - size.height) / 2.0
    return CGRect(x: 0, y: yOffset, width: size.width, height: size.height)
  }

  private func fallbackSize() -> CGSize {
    let font = MDFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
    let text = latex as NSString
    let textSize = text.size(withAttributes: [.font: font])
    let width = max(textSize.width, 10).rounded(.up)
    let height = max(textSize.height, fontSize).rounded(.up)
    return CGSize(width: width, height: height)
  }

  private func measuredAttachmentSize(proposedLineFragmentWidth: CGFloat) -> CGSize {
    let label = MTMathUILabel()
    try? MathExceptionCatcher.try {
      label.latex = self.latex
    }
    label.fontSize = fontSize
    label.displayErrorInline = false

    var size: CGSize = .zero
    do {
      try MathExceptionCatcher.try {
        #if canImport(UIKit)
        let targetWidth = proposedLineFragmentWidth.isFinite && proposedLineFragmentWidth > 0
          ? proposedLineFragmentWidth
          : CGFloat.greatestFiniteMagnitude
        size = label.sizeThatFits(CGSize(width: targetWidth, height: .greatestFiniteMagnitude))
        #elseif canImport(AppKit)
        size = label.intrinsicContentSize
        #endif
      }
    } catch {
      MathRenderDiagnostics.logInlineMath(source: "attachmentBounds/fallback", latex: latex)
      return fallbackSize()
    }

    guard size.width.isFinite, size.height.isFinite,
          size.width > 0, size.height > 0 else {
      MathRenderDiagnostics.logInlineMath(source: "attachmentBounds/fallback", latex: latex)
      return fallbackSize()
    }

    MathRenderDiagnostics.logInlineMathIfInteresting(source: "attachmentBounds", latex: latex)
    return CGSize(width: size.width.rounded(.up), height: size.height.rounded(.up) + 1)
  }
}
