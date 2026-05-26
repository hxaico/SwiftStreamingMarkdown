//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Foundation
import Markdown
import SwiftUI

/// A markdown block that can be converted into `MarkdownRenderable`

protocol BlockConvertible {

  /// Convert into `MarkdownRenderable`
  /// - Parameter attributeContainer: The inherited attributes
  /// - Parameter config: The mark down rendering config used to override fonts & text color if needed.
  /// - Parameter colorScheme: The color scheme used by the view. It's used to determine the font color during conversion.
  /// - Returns: A `MarkdownRenderable` that is ready to be rendered by Views.
  func convert(attributeContainer: NSAttributeContainer, config: MarkdownRenderConfig, colorScheme: ColorScheme) -> MarkdownRenderable
}

extension Markup {
  var blockConvertibleChildren: [BlockConvertible] {
    return self.children.compactMap { $0 as? BlockConvertible }
  }
}
