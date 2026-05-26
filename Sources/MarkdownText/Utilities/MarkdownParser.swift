//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Markdown

/// Parse a given text into a markdown tree, represented by `Document`
public protocol MarkdownParser {

  /// Perform the parsing
  /// - Parameter text: The incoming text
  /// - Parameter option: The option for parsing
  /// - Returns: The parse result
  func parse(text: String, option: MarkdownParseOption) async -> MarkdownParseResult
}

extension MarkdownParser {

  public func parse(text: String) async -> Document {
    return await parse(text: text, option: .init(speculativeRewrite: false)).document
  }
}

public struct MarkdownParseOption {
  /// Whether to speculative rewrite the markdown if it is considered as incomplete
  /// Such as a string ends with a partial table or partial emphasis
  public let speculativeRewrite: Bool

  public init(speculativeRewrite: Bool) {
    self.speculativeRewrite = speculativeRewrite
  }
}

public struct MarkdownParseResult {
  public let document: Document
  public let speculativeRewritten: Bool
}

public final class MarkdownParserImpl: MarkdownParser {

  private let rewriters: [MarkupPostParsingRewriter] = [
    PartialStrongMarkupPostParsingRewriter(),
    PartialTableMarkupPostParsingRewriter()
  ]

  private let latexPreprocessor: LaTexPreProcessor

  public init() {
    self.latexPreprocessor = LaTexPreProcessorImpl()
  }

  public func parse(text: String, option: MarkdownParseOption) async -> MarkdownParseResult {
    let targetString = latexPreprocessor.process(input: text)

    var result: MarkdownParseResult = MarkdownParseResult(
      document: Document(parsing: targetString),
      speculativeRewritten: false
    )

    if option.speculativeRewrite {
      for rewriter in rewriters {
        if let rewrittenDoc = rewriter.rewriteIfApplicable(document: result.document) {
          result = MarkdownParseResult(document: rewrittenDoc, speculativeRewritten: true)
        }
      }
    }
    return result
  }
}
