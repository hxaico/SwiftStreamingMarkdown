//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation
import OSLog

/// String-only diagnostics for LaTeX rendering. Never touches UIKit views.
enum MathRenderDiagnostics {
  private static let logger = Logger(subsystem: "SwiftStreamingMarkdown", category: "MathRender")

  static func preview(_ latex: String, maxLength: Int = 120) -> String {
    let collapsed = latex
      .replacingOccurrences(of: "\n", with: "\\n")
      .trimmingCharacters(in: .whitespacesAndNewlines)
    guard collapsed.count > maxLength else { return collapsed }
    return String(collapsed.prefix(maxLength)) + "…"
  }

  static func logBlockMathIfInteresting(source: String, latex: String) {
    logBlockMath(source: source, latex: latex)
  }

  static func logBlockMath(source: String, latex: String) {
    guard MarkdownDiagnosticsLogging.isEnabled else { return }
    logger.info(
      """
      [BlockMath] source=\(source, privacy: .public) \
      len=\(latex.count, privacy: .public) \
      preview='\(preview(latex), privacy: .public)'
      """
    )
  }

  static func logInlineMathIfInteresting(source: String, latex: String) {
    logInlineMath(source: source, latex: latex)
  }

  static func logInlineMath(source: String, latex: String) {
    guard MarkdownDiagnosticsLogging.isEnabled else { return }
    logger.info(
      """
      [InlineMath] source=\(source, privacy: .public) \
      len=\(latex.count, privacy: .public) \
      preview='\(preview(latex), privacy: .public)'
      """
    )
  }

  static func logCodeBlockLayoutIfInteresting(
    source: String,
    language: String,
    code: String,
    size: CGSize
  ) {
    guard MarkdownDiagnosticsLogging.isEnabled else { return }
    let interesting = code.isEmpty
      || size.height <= 1
      || size.width <= 1
      || !size.height.isFinite
      || !size.width.isFinite
    guard interesting else { return }
    logger.info(
      """
      [CodeBlock/layout] source=\(source, privacy: .public) lang=\(language, privacy: .public) \
      codeLen=\(code.count, privacy: .public) size=\(Int(size.width.rounded()), privacy: .public)x\(Int(size.height.rounded()), privacy: .public) \
      preview='\(preview(code), privacy: .public)'
      """
    )
  }

  static func logParseSummary(textLength: Int, renderables: [MarkdownRenderable]) {
    guard MarkdownDiagnosticsLogging.isEnabled else { return }
    let latexBlocks = collectLatexBlocks(in: renderables)
    let codeBlocks = renderables.filter(\.isCodeBlock)
    let emptyLatexCount = latexBlocks.filter { $0.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count

    logger.info(
      """
      [Parse] textLen=\(textLength, privacy: .public) renderables=\(renderables.count, privacy: .public) \
      codeBlocks=\(codeBlocks.count, privacy: .public) latexBlocks=\(latexBlocks.count, privacy: .public) \
      emptyLatex=\(emptyLatexCount, privacy: .public)
      """
    )

    for (index, block) in codeBlocks.enumerated() {
      if case let .codeBlock(_, language, code) = block {
        logger.info(
          """
          [Parse/Code] #\(index, privacy: .public) lang=\(language ?? "nil", privacy: .public) \
          len=\(code.count, privacy: .public) preview='\(preview(code), privacy: .public)'
          """
        )
      }
    }

    for (index, block) in latexBlocks.enumerated() {
      logger.info(
        """
        [Parse/Latex] #\(index, privacy: .public) id=\(block.id, privacy: .public) \
        preview='\(preview(block.content), privacy: .public)'
        """
      )
    }
  }

  private static func collectLatexBlocks(
    in renderables: [MarkdownRenderable]
  ) -> [(id: String, content: String)] {
    var blocks: [(id: String, content: String)] = []
    for renderable in renderables {
      switch renderable {
      case let .latex(id, content):
        blocks.append((id, content))
      case let .orderedList(_, items):
        for item in items {
          blocks.append(contentsOf: collectLatexBlocks(in: item.children))
        }
      case let .unorderedList(_, items, _):
        for item in items {
          blocks.append(contentsOf: collectLatexBlocks(in: item.children))
        }
      default:
        break
      }
    }
    return blocks
  }
}
