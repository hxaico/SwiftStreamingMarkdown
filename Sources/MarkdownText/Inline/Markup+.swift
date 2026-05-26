//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Foundation
import Markdown

extension Markup {

  var inlineConvertibleChildren: [InlineConvertible] {
    return self.children.compactMap { $0 as? InlineConvertible }
  }
}
