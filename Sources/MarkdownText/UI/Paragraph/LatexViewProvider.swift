//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation
import iosMath
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
    label.latex = latex
    label.textColor = textColor
    label.displayErrorInline = false
    label.fontSize = fontSize
    label.setContentHuggingPriority(.defaultHigh, for: .vertical)
    self.view = label
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

  private func measuredAttachmentSize(proposedLineFragmentWidth: CGFloat) -> CGSize {
    let label: MTMathUILabel
    if let existingLabel = view as? MTMathUILabel {
      label = existingLabel
    } else {
      label = MTMathUILabel()
      label.latex = latex
      label.fontSize = fontSize
      label.displayErrorInline = false
    }

    #if canImport(UIKit)
    let targetWidth = proposedLineFragmentWidth.isFinite && proposedLineFragmentWidth > 0
      ? proposedLineFragmentWidth
      : CGFloat.greatestFiniteMagnitude
    let size = label.sizeThatFits(CGSize(width: targetWidth, height: .greatestFiniteMagnitude))
    #elseif canImport(AppKit)
    let size = label.intrinsicContentSize
    #endif

    guard size.width.isFinite, size.height.isFinite,
          size.width > 0, size.height > 0 else {
      MathRenderDiagnostics.logInlineMath(source: "attachmentBounds/fallback", latex: latex)
      return CGSize(width: 1, height: fontSize.rounded(.up))
    }

    MathRenderDiagnostics.logInlineMathIfInteresting(source: "attachmentBounds", latex: latex)
    return CGSize(width: size.width.rounded(.up), height: size.height.rounded(.up) + 1.0)
  }
}
