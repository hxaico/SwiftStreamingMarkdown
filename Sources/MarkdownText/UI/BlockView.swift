//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Foundation
import SVGView
import SwiftUI

struct BlockView: View {

  var horizontalPadding: CGFloat
  let renderables: [MarkdownRenderable]

  init(renderables: [MarkdownRenderable], horizontalPadding: CGFloat) {
    self.renderables = renderables
    self.horizontalPadding = horizontalPadding
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 30) {
      ForEach(renderables) { renderable in
        SingleBlockView(
          renderable: renderable,
          horizontalPadding: horizontalPadding)
      }
    }
  }
}

struct SingleBlockView: View {

  @Environment(\.markdownConfig) var config: MarkdownRenderConfig

  let renderable: MarkdownRenderable
  let horizontalPadding: CGFloat

  init(renderable: MarkdownRenderable, horizontalPadding: CGFloat) {
    self.renderable = renderable
    self.horizontalPadding = horizontalPadding
  }

  var body: some View {
    Group {
      switch renderable {
      case .heading(_, _, let contents):
        HStack(spacing: 0) {
          ParagraphView(contents: contents)
            .padding(.horizontal, horizontalPadding)
            .transition(.opacity)
            .accessibilityAddTraits(.isHeader)
          Spacer()
        }
      case .paragraph(_, let contents):
        HStack(spacing: 0) {
          ParagraphView(contents: contents, lineSpacing: 5)
            .fixedSize(horizontal: false, vertical: true)
            .transition(.opacity)
          Spacer()
        }
        .padding(.horizontal, horizontalPadding)
      case .latex(_, let latexString):
        ScrollView(.horizontal) {
          HStack(spacing: 0) {
            BlockMathView(latex: latexString, color: Color(config.paragraphStyle.textColor))
            Spacer()
          }
          .padding(.horizontal, horizontalPadding)
        }.scrollIndicators(.hidden)
      case .orderedList(_, let items):
        OrderedListView(items: items, horizontalPadding: horizontalPadding)
          .padding(.horizontal, horizontalPadding)
      case .unorderedList(_, let items, let nestedLevel):
        UnorderedListView(items: items,
                          nestedLevel: nestedLevel,
                          horizontalPadding: horizontalPadding)
          .padding(.horizontal, horizontalPadding)
      case .codeBlock(_, let language, let code):
        CodeBlockView(language: language ?? "",
                      code: code)
          .padding(.horizontal, horizontalPadding)
      case .thematicBreak:
        ThematicBreakView()
      case .table(_, let headers, let rows, let rawMarkdown):
        TableView(headings: headers,
                  rows: rows,
                  horizontalPadding: horizontalPadding,
                  rawMarkdown: rawMarkdown)
      case .blockQuote(_, let item):
        BlockQuoteView(item: item)
          .padding(.horizontal, horizontalPadding)
      }
    }
  }
}
