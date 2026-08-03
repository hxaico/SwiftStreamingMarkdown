//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import SwiftUI
import iosMath
import MathExceptionCatcher

struct BlockMathContainer: View {
  let latex: String
  let color: Color
  let pointSize: CGFloat

  @State private var didFail: Bool = false

  init(
    latex: String,
    color: Color = Color.Theme.Foreground.Primary.Primary750,
    pointSize: CGFloat = Typography.base.mdFont.pointSize
  ) {
    self.latex = latex
    self.color = color
    self.pointSize = pointSize
  }

  var body: some View {
    Group {
      if !MarkdownLatexSanitizer.shouldRenderBlockMath(latex) || didFail {
        FallbackMathTextView(latex: latex)
      } else {
        ScrollView(.horizontal, showsIndicators: false) {
          BlockMathView(
            latex: latex,
            color: color,
            pointSize: pointSize,
            onFailure: {
              didFail = true
            }
          )
          .fixedSize(horizontal: true, vertical: true)
        }
        .fixedSize(horizontal: false, vertical: true)
      }
    }
    .onChange(of: latex) { _ in
      didFail = false
    }
  }
}

struct FallbackMathTextView: View {
  @Environment(\.markdownConfig) private var config: MarkdownRenderConfig

  let latex: String

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      Text(latex)
        .font(Typography.codeTextFonts)
        .foregroundStyle(config.mathStyle.textColor)
        .padding(.vertical, 4)
    }
    .fixedSize(horizontal: false, vertical: true)
  }
}

#if canImport(UIKit)

struct BlockMathView: UIViewRepresentable, Equatable {
  let latex: String
  let color: Color
  let pointSize: CGFloat
  let onFailure: (() -> Void)?

  init(
    latex: String,
    color: Color = Color.Theme.Foreground.Primary.Primary750,
    pointSize: CGFloat = Typography.base.mdFont.pointSize,
    onFailure: (() -> Void)? = nil
  ) {
    self.latex = latex
    self.color = color
    self.pointSize = pointSize
    self.onFailure = onFailure
  }

  static func == (lhs: BlockMathView, rhs: BlockMathView) -> Bool {
    lhs.latex == rhs.latex && lhs.color == rhs.color && lhs.pointSize == rhs.pointSize
  }

  func makeUIView(context: Context) -> MTMathUILabel {
    MathRenderDiagnostics.logBlockMathIfInteresting(source: "makeUIView", latex: latex)
    let label = MTMathUILabel()
    label.textColor = UIColor(color)
    label.displayErrorInline = false
    label.fontSize = pointSize
    label.setContentHuggingPriority(.defaultHigh, for: .vertical)
    applyLatex(to: label)
    return label
  }

  func updateUIView(_ uiView: MTMathUILabel, context: Context) {
    MathRenderDiagnostics.logBlockMathIfInteresting(source: "updateUIView", latex: latex)
    uiView.textColor = UIColor(color)
    applyLatex(to: uiView)
  }

  func sizeThatFits(_ proposal: ProposedViewSize, uiView: MTMathUILabel, context: Context) -> CGSize? {
    guard MarkdownLatexSanitizer.shouldRenderBlockMath(latex) else {
      return .zero
    }
    return measuredSize(for: uiView)
  }

  @discardableResult
  private func applyLatex(to label: MTMathUILabel) -> CGSize? {
    guard MarkdownLatexSanitizer.shouldRenderBlockMath(latex) else {
      clearLabel(label)
      notifyFailure()
      return nil
    }

    do {
      try MathExceptionCatcher.try {
        label.isHidden = false
        label.latex = latex
      }
    } catch {
      MathRenderDiagnostics.logBlockMath(
        source: "applyLatex/objcException",
        latex: latex
      )
      clearLabel(label)
      notifyFailure()
      return nil
    }

    guard let size = measuredSize(for: label) else {
      clearLabel(label)
      notifyFailure()
      return nil
    }
    return size
  }

  private func clearLabel(_ label: MTMathUILabel) {
    label.latex = ""
    label.bounds = .zero
    label.frame = .zero
    label.isHidden = true
  }

  private func measuredSize(for label: MTMathUILabel) -> CGSize? {
    var rawSize: CGSize = .zero
    do {
      try MathExceptionCatcher.try {
        rawSize = label.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
      }
    } catch {
      MathRenderDiagnostics.logBlockMath(
        source: "measuredSize/objcException",
        latex: latex
      )
      return nil
    }

    guard rawSize.width.isFinite, rawSize.height.isFinite,
          rawSize.width > 0, rawSize.height > 0 else {
      MathRenderDiagnostics.logBlockMath(source: "measuredSize/unrenderable", latex: latex)
      return nil
    }
    return CGSize(width: rawSize.width.rounded(.up), height: rawSize.height.rounded(.up) + 1)
  }

  private func notifyFailure() {
    Task { @MainActor in
      onFailure?()
    }
  }
}

#elseif canImport(AppKit)

struct BlockMathView: NSViewRepresentable, Equatable {
  let latex: String
  let color: Color
  let pointSize: CGFloat
  let onFailure: (() -> Void)?

  init(
    latex: String,
    color: Color = Color.Theme.Foreground.Primary.Primary750,
    pointSize: CGFloat = Typography.base.mdFont.pointSize,
    onFailure: (() -> Void)? = nil
  ) {
    self.latex = latex
    self.color = color
    self.pointSize = pointSize
    self.onFailure = onFailure
  }

  static func == (lhs: BlockMathView, rhs: BlockMathView) -> Bool {
    lhs.latex == rhs.latex && lhs.color == rhs.color && lhs.pointSize == rhs.pointSize
  }

  func makeNSView(context: Context) -> MTMathUILabel {
    MathRenderDiagnostics.logBlockMathIfInteresting(source: "makeNSView", latex: latex)
    let label = MTMathUILabel()
    label.textColor = NSColor(color)
    label.displayErrorInline = false
    label.fontSize = pointSize
    label.setContentHuggingPriority(.defaultHigh, for: .vertical)
    applyLatex(to: label)
    return label
  }

  func updateNSView(_ nsView: MTMathUILabel, context: Context) {
    MathRenderDiagnostics.logBlockMathIfInteresting(source: "updateNSView", latex: latex)
    nsView.textColor = NSColor(color)
    applyLatex(to: nsView)
  }

  func sizeThatFits(_ proposal: ProposedViewSize, nsView: MTMathUILabel, context: Context) -> CGSize? {
    guard MarkdownLatexSanitizer.shouldRenderBlockMath(latex) else {
      return .zero
    }
    var size: CGSize = .zero
    do {
      try MathExceptionCatcher.try {
        size = nsView.intrinsicContentSize
      }
    } catch {
      return nil
    }
    guard size.width.isFinite, size.height.isFinite,
          size.width > 0, size.height > 0 else {
      return nil
    }
    return CGSize(width: size.width.rounded(.up), height: size.height.rounded(.up) + 1)
  }

  private func applyLatex(to label: MTMathUILabel) {
    guard MarkdownLatexSanitizer.shouldRenderBlockMath(latex) else {
      label.latex = ""
      notifyFailure()
      return
    }
    do {
      try MathExceptionCatcher.try {
        label.latex = latex
      }
      if label.mathList == nil {
        notifyFailure()
      }
    } catch {
      notifyFailure()
    }
  }

  private func notifyFailure() {
    Task { @MainActor in
      onFailure?()
    }
  }
}

#endif
