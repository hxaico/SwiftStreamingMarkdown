//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

/// Options that control how a `MarkdownParser` processes input text.
public struct MarkdownParseOption {
  /// Whether to speculative rewrite the markdown if it is considered as incomplete
  /// Such as a string ends with a partial table or partial emphasis
  public let speculativeRewrite: Bool

  /// Specify how to parse latex
  public let latexMatchingRules: [LatexMatching]

  /// Custom preprocessor extension hook
  public let preprocessor: MarkdownPreprocessorProtocol?

  /// Whether to enable experimental block-level handling of Markdown images.
  ///
  /// When enabled, the parser rewrites paragraphs that contain images so each
  /// image is isolated into its own block-level paragraph.
  ///
  /// - Important: Image support is **experimental** and incomplete. There is no
  ///   image renderer yet, so an isolated image paragraph currently renders as
  ///   empty; enabling this only changes the parsed document structure. The
  ///   behavior, API, and rendering output may change in future releases.
  ///   Defaults to `false`.
  public let imageSupport: Bool

  /// Create a new parse option.
  /// - Parameters:
  ///   - speculativeRewrite: See `speculativeRewrite`.
  ///   - latexMatchingRules: See `latexMatchingRules`. Defaults to every supported rule.
  ///   - preprocessor: The custom preprocessor to apply. Defaults to nil.
  ///   - imageSupport: See `imageSupport`. Experimental; defaults to `false`.
  public init(
    speculativeRewrite: Bool,
    latexMatchingRules: [LatexMatching] = LatexMatching.allCases,
    preprocessor: MarkdownPreprocessorProtocol? = nil,
    imageSupport: Bool = false
  ) {
    self.speculativeRewrite = speculativeRewrite
    self.latexMatchingRules = latexMatchingRules
    self.preprocessor = preprocessor
    self.imageSupport = imageSupport
  }

  /// The set of delimiter forms the LaTeX preprocessor will recognize. Omitting
  /// a case leaves text matching that delimiter as plain markdown.
  public enum LatexMatching: String, Hashable, CaseIterable {
    /// Inline LaTeX delimited by `\(` … `\)`.
    case inlineSlashBracket
    /// Block LaTeX delimited by `$$` … `$$`.
    case blockDollar
    /// Block LaTeX delimited by `\[` … `\]`.
    case blockSlashBracket
  }
}
