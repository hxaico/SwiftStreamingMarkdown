//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Foundation
import SwiftUI

extension View {
  func border(width: CGFloat, edges: [Edge], color: Color) -> some View {
    overlay(EdgeBorder(width: width, edges: edges).foregroundColor(color))
  }

  public func borderRadius<S>(_ content: S, width: CGFloat = 1, cornerRadius: CGFloat, corners: UIRectCorner) -> some View where S: ShapeStyle {
    let roundedRect = RoundedCorner(radius: cornerRadius, corners: corners)
    return clipShape(roundedRect)
      .overlay(roundedRect.stroke(content, lineWidth: width))
  }
}

struct EdgeBorder: Shape {
  var width: CGFloat
  var edges: [Edge]

  func path(in rect: CGRect) -> Path {
    edges.map { edge -> Path in
      switch edge {
      case .top: return Path(.init(x: rect.minX, y: rect.minY, width: rect.width, height: width))
      case .bottom: return Path(.init(x: rect.minX, y: rect.maxY - width, width: rect.width, height: width))
      case .leading: return Path(.init(x: rect.minX, y: rect.minY, width: width, height: rect.height))
      case .trailing: return Path(.init(x: rect.maxX - width, y: rect.minY, width: width, height: rect.height))
      }
    }.reduce(into: Path()) { $0.addPath($1) }
  }
}

struct RoundedCorner: Shape {
  /* This may seem a bit redundant with EdgeBorder, but the Bezier path here doesn't seem to render a border as thick as EdgeBorder */
  var radius: CGFloat = .infinity
  var corners: UIRectCorner = .allCorners

  func path(in rect: CGRect) -> Path {
    let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
    return Path(path.cgPath)
  }
}
