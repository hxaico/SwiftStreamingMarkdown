//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation
import RegexBuilder

/// A protocol defined inside SwiftStreamingMarkdown to delegate host-specific (app-side) preprocessing
/// and sanitization tasks. This decouples the library from specific rendering engines (like `iosMath`)
/// or custom string replacements.
public protocol MarkdownPreprocessorProtocol: Sendable {
  /// Preprocesses the raw markdown string (e.g. wrapping bare LaTeX commands or mapping block tags)
  /// before it is parsed by the library.
  func preprocess(_ input: String) -> String

  /// Sanitizes raw LaTeX formulas (e.g. converting unsupported syntax/tokens) before they are
  /// passed to the math rendering engine.
  func sanitizeMath(_ latex: String, isBlock: Bool) -> String
}

public extension MarkdownPreprocessorProtocol {
  func preprocess(_ input: String) -> String { input }
  func sanitizeMath(_ latex: String, isBlock: Bool) -> String { latex }
}



/// Pre-process the inline and block latex in markdown.
/// This is a less heavy-weight approach than forking commonmark-gfm and swift-markdown to support parsing latex nodes.
protocol LaTexPreProcessor {
  func process(
    input: String,
    matchingRules: [MarkdownParseOption.LatexMatching],
    customExtension: MarkdownPreprocessorProtocol?
  ) -> String
}

extension LaTexPreProcessor {
  func process(input: String) -> String {
    return process(
      input: input,
      matchingRules: MarkdownParseOption.LatexMatching.allCases,
      customExtension: nil
    )
  }
}

final class LaTexPreProcessorImpl: LaTexPreProcessor {

  static let latexRef = Reference(Substring.self)
  static let latexOpenIndentation = Reference(Substring.self)

  static let dollarBlockMath = Regex {
    Anchor.startOfLine
    Capture(as: latexOpenIndentation) {
      ZeroOrMore(.horizontalWhitespace)
    }
    "$$"
    Capture(as: latexRef) {
      OneOrMore(.any, .reluctant)
    }
    ZeroOrMore(.horizontalWhitespace)
    "$$"
    ZeroOrMore(.horizontalWhitespace)
    Anchor.endOfLine
  }

  static let slashBracketMath = Regex {
    Anchor.startOfLine
    Capture(as: latexOpenIndentation) {
      ZeroOrMore(.horizontalWhitespace)
    }
    "\\["
    Capture(as: latexRef) {
      OneOrMore(.any, .reluctant)
    }
    ZeroOrMore(.horizontalWhitespace)
    "\\]"
    ZeroOrMore(.horizontalWhitespace)
    Anchor.endOfLine
  }

  static let inlineParenthesisMath = Regex {
    "\\("
    Capture(as: latexRef) {
      OneOrMore(.any, .reluctant)
    }
    "\\)"
  }

  static let boxedLatex = Regex {
    Capture {
      "\\boxed"
    }
  }

  static let textLatex = Regex {
    Capture {
      "\\text"
    }
  }

  static let dfracLatex = Regex {
    Capture {
      "\\dfrac"
    }
  }

  static let tfracLatex = Regex {
    Capture {
      "\\tfrac"
    }
  }

  static let bracketSize = Regex {
    Capture {
      ChoiceOf {
        "\\bigl"
        "\\biggl"
        "\\Bigl"
        "\\Biggl"
        "\\bigr"
        "\\biggr"
        "\\Bigr"
        "\\Biggr"
        "\\big"
      }
    }
  }

  static let primeLatex = Regex {
    Capture {
      "'"
    }
  }

  static let vectorLatex = Regex {
    Capture {
      "\\overrightarrow"
    }
  }

  static let rightArrowLatex = Regex {
    Capture {
      "\\implies"
    }
  }

  static let harpoonsLatex = Regex {
    Capture {
      "\\rightleftharpoons"
    }
  }

  static let dotsLatex = Regex {
    Capture {
      "\\dots"
    }
  }

  static let customCodeType = "blockmath"
  static let inlineCodePrefix = "\\("
  static let inlineCodeSuffix = "\\)"
  static let newline = "\n"

  init() {}

  func process(
    input: String,
    matchingRules: [MarkdownParseOption.LatexMatching],
    customExtension: MarkdownPreprocessorProtocol?
  ) -> String {
    let extended = customExtension?.preprocess(input) ?? input
    let closed = closeUnclosedDisplayMath(extended)
    let rules = Set(matchingRules)
    let result = processBlockMath(input: closed, rules: rules, customExtension: customExtension)
    return processInlineMath(input: result, rules: rules, customExtension: customExtension)
  }

  /// This replace block math with a special code block node. By treating it as a code block it will avoid over escaping characters within latex.
  func processBlockMath(
    input: String,
    rules: Set<MarkdownParseOption.LatexMatching>,
    customExtension: MarkdownPreprocessorProtocol?
  ) -> String {
    var result = input
    if rules.contains(.blockDollar) {
      result.replace(Self.dollarBlockMath, with: { match in
        let indentation = match[Self.latexOpenIndentation]
        let latex = match[Self.latexRef]
        let sanitized = customExtension?.sanitizeMath(String(latex), isBlock: true) ?? String(latex)
        return Self.buildCodeBlock(indentation: indentation, latex: sanitized)
      })
    }

    if rules.contains(.blockSlashBracket) {
      result.replace(Self.slashBracketMath, with: { match in
        let indentation = match[Self.latexOpenIndentation]
        let latex = match[Self.latexRef]
        let sanitized = customExtension?.sanitizeMath(String(latex), isBlock: true) ?? String(latex)
        return Self.buildCodeBlock(indentation: indentation, latex: sanitized)
      })
    }
    return result
  }

  /// This wraps inline math as inline code to avoid over-unescaping issue
  func processInlineMath(
    input: String,
    rules: Set<MarkdownParseOption.LatexMatching>,
    customExtension: MarkdownPreprocessorProtocol?
  ) -> String {
    guard rules.contains(.inlineSlashBracket) else { return input }
    return input.replacing(Self.inlineParenthesisMath, with: { match in
      let latex = String(match[Self.latexRef])
      let sanitized = customExtension?.sanitizeMath(latex, isBlock: false) ?? latex
      return "`\\(\(sanitized)\\)`"
    })
  }

  // MARK: - Convenience overloads (default to every supported rule)

  func processBlockMath(input: String) -> String {
    return processBlockMath(input: input, rules: Set(MarkdownParseOption.LatexMatching.allCases), customExtension: nil)
  }

  func processInlineMath(input: String) -> String {
    return processInlineMath(input: input, rules: Set(MarkdownParseOption.LatexMatching.allCases), customExtension: nil)
  }

  private static func buildCodeBlock(indentation: Substring, latex: String) -> String {
    let processedLatex = latex.trimmingCharacters(in: .newlines)
    let nextLineIntendation = latex.hasPrefix(Self.newline) ? "" : indentation
    return "\(indentation)```\(Self.customCodeType)\(Self.newline)\(nextLineIntendation)\(processedLatex)\(Self.newline)\(indentation)```"
  }

  private func closeUnclosedDisplayMath(_ text: String) -> String {
    let lines = text.components(separatedBy: "\n")
    var inCodeBlock = false
    var activeFenceChar: Character?
    var activeFenceLength = 0
    var displayMathOpenDelimiter: String?

    for line in lines {
      let trimmed = line.trimmingCharacters(in: .whitespaces)

      if let fence = parseFence(line: line) {
        if inCodeBlock {
          if fence.char == activeFenceChar, fence.length >= activeFenceLength {
            inCodeBlock = false
            activeFenceChar = nil
            activeFenceLength = 0
          }
        } else {
          inCodeBlock = true
          activeFenceChar = fence.char
          activeFenceLength = fence.length
        }
      }

      guard !inCodeBlock else { continue }

      if let open = displayMathOpenDelimiter {
        let closingSuffix = open == "$$" ? "$$" : "\\]"
        if trimmed.hasSuffix(closingSuffix) || trimmed.contains(closingSuffix) {
          displayMathOpenDelimiter = nil
        }
      } else {
        if trimmed.hasPrefix("$$") && !trimmed.dropFirst(2).contains("$$") {
          displayMathOpenDelimiter = "$$"
        } else if trimmed.hasPrefix("\\[") && !trimmed.dropFirst(2).contains("\\]") {
          displayMathOpenDelimiter = "\\["
        }
      }
    }

    if let open = displayMathOpenDelimiter {
      let closing = open == "$$" ? "\n$$" : "\n\\]"
      return text + closing
    }
    return text
  }

  private func parseFence(line: String) -> (char: Character, length: Int)? {
    let trimmed = line.trimmingCharacters(in: .whitespaces)
    guard trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") else { return nil }
    let char = trimmed.first!
    let length = trimmed.prefix(while: { $0 == char }).count
    return (char, length)
  }
}

public enum MarkdownLatexSanitizer {
  public enum LatexFlags: Hashable, Sendable {
    case balancedBraces
    case balancedLeftRight
  }

  public static func shouldRenderBlockMath(_ latex: String) -> Bool {
    let flags = flags(for: latex)
    return flags.contains(.balancedBraces) && flags.contains(.balancedLeftRight)
  }

  public static func flags(for latex: String) -> Set<LatexFlags> {
    var flags = Set<LatexFlags>()
    if !hasUnbalancedBraces(latex) {
      flags.insert(.balancedBraces)
    }
    if !hasUnbalancedLeftRight(latex) {
      flags.insert(.balancedLeftRight)
    }
    return flags
  }

  public static func hasUnbalancedBraces(_ latex: String) -> Bool {
    var braceCount = 0
    for char in latex {
      if char == "{" {
        braceCount += 1
      } else if char == "}" {
        braceCount -= 1
        if braceCount < 0 {
          return true
        }
      }
    }
    return braceCount != 0
  }

  public static func hasUnbalancedLeftRight(_ latex: String) -> Bool {
    var leftCount = 0
    var index = latex.startIndex
    while index < latex.endIndex {
      let suffix = latex[index...]
      if suffix.hasPrefix("\\left") {
        let nextIndex = latex.index(index, offsetBy: 5, limitedBy: latex.endIndex) ?? latex.endIndex
        if nextIndex == latex.endIndex || !latex[nextIndex].isLetter {
          leftCount += 1
          index = nextIndex
          continue
        }
      }
      if suffix.hasPrefix("\\right") {
        let nextIndex = latex.index(index, offsetBy: 6, limitedBy: latex.endIndex) ?? latex.endIndex
        if nextIndex == latex.endIndex || !latex[nextIndex].isLetter {
          leftCount -= 1
          if leftCount < 0 {
            return true
          }
          index = nextIndex
          continue
        }
      }
      index = latex.index(after: index)
    }
    return leftCount != 0
  }
}

