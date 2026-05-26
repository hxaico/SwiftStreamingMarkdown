//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import SwiftUI
import SwiftStreamingMarkdown

struct DemonstrationView: View {
  let demonstration: Demonstration
  let markdownText: String

  var body: some View {
    ScrollView {
      MarkdownView(
        text: markdownText,
        horizontalPadding: 16,
        config: .default
      )
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.vertical, 16)
    }
    .navigationTitle(demonstration.rawValue)
    .navigationBarTitleDisplayMode(.inline)
  }
}
