//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Foundation
import Markdown
import SwiftUI

extension ThematicBreak: BlockConvertible {

  func convert(attributeContainer: NSAttributeContainer, config: MarkdownRenderConfig, colorScheme: ColorScheme) -> MarkdownRenderable {
    return MarkdownRenderable.thematicBreak(id: self.id)
  }
}
