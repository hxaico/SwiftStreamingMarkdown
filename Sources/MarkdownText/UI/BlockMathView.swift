//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import iosMath
import SwiftUI

public struct BlockMathView: UIViewRepresentable {
  public let latex: String
  public let color: Color
  public let pointSize: CGFloat

  public init(latex: String, color: Color = Color.Theme.Foreground.Primary.Primary750, pointSize: CGFloat = Typography.base.uiFont.pointSize) {
    self.latex = latex
    self.color = color
    self.pointSize = pointSize
  }

  public func makeUIView(context: Context) -> MTMathUILabel {
    let label = MTMathUILabel()
    label.latex = latex
    label.textColor = UIColor(color)
    label.displayErrorInline = false
    label.fontSize = pointSize
    label.setContentHuggingPriority(.defaultHigh, for: .vertical)
    return label
  }

  public func updateUIView(_ uiView: MTMathUILabel, context: Context) {
    uiView.textColor = UIColor(color)
    uiView.latex = latex
  }

  public func sizeThatFits(_ proposal: ProposedViewSize, uiView: MTMathUILabel, context: Context) -> CGSize? {
    uiView.sizeToFit()
    let size = uiView.bounds.size
    // It's a known issue that MTMathUILabel may be cut off for some short statement. Manually add 1 to the height fix it.
    return CGSize(width: size.width.rounded(.up), height: size.height.rounded(.up) + 1)
  }
}
