//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import SwiftUI

extension View {
  @ViewBuilder
  func `if`<Content: View>(_ condition: Bool, content: (Self) -> Content) -> some View {
    if condition {
      content(self)
    } else {
      self
    }
  }
}
