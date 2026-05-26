//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import SwiftUI
import SwiftStreamingMarkdown

struct DemonstrationView: View {
  @AppStorage(SampleSettings.preferStreamedMarkdownKey) private var preferStreamedMarkdown = true

  let demonstration: Demonstration
  let markdownText: String

  private var streamedRenderConfig: MarkdownRenderConfig {
    MarkdownRenderConfig(copyFrom: .default, shouldAnimateText: true)
  }

  var body: some View {
    ScrollView {
      Group {
        if preferStreamedMarkdown {
          StreamedMarkdownView(
            text: markdownText,
            horizontalPadding: 16,
            config: streamedRenderConfig,
            chunkInterval: 0.2
          )
        } else {
          MarkdownView(
            text: markdownText,
            horizontalPadding: 16,
            config: .default
          )
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.vertical, 16)
    }
    .navigationTitle(demonstration.rawValue)
    .navigationBarTitleDisplayMode(.inline)
  }
}
