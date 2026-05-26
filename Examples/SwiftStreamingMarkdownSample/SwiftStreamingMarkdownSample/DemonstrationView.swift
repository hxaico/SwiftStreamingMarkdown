//
//  DemonstrationView.swift
//  SwiftStreamingMarkdownSample
//
//  Created by Jun Yan on 5/26/26.
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
