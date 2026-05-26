//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Foundation
import SwiftUI
@testable import SwiftStreamingMarkdown

/// A Canvas view for convenience of SwiftUI previews or snapshot tests.
/// It disables all animation by default.
public struct CanvasView<Content: View>: View {

  public let content: (() -> Content)

  public init(content: @escaping () -> Content) {
    self.content = content
  }

  public var body: some View {
    VStack {
      content()
      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.Theme.Background.Page.Chat.Flat)
    .transaction { tr in tr.animation = nil }
  }
}
