//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation
import Markdown
import SwiftUI

extension CodeBlock: BlockConvertible {
  func convert(attributeContainer: NSAttributeContainer, config: MarkdownRenderConfig) -> MarkdownRenderable {
    let lang = self.language?.lowercased() ?? ""
    if lang == LaTexPreProcessorImpl.customCodeType || lang == "latex" || lang == "tex" || lang == "math" || lang == "katex" {
      var cleanCode = self.code
      if cleanCode.hasPrefix("```blockmath") || cleanCode.hasPrefix("```latex") || cleanCode.hasPrefix("```tex") || cleanCode.hasPrefix("```math") {
        if let firstNewline = cleanCode.firstIndex(of: "\n") {
          cleanCode = String(cleanCode[cleanCode.index(after: firstNewline)...])
        }
      }
      let trimmed = cleanCode.trimmingCharacters(in: .whitespacesAndNewlines)
      if trimmed.hasSuffix("```") {
        cleanCode = String(trimmed.dropLast(3)).trimmingCharacters(in: .whitespacesAndNewlines)
      } else {
        cleanCode = trimmed
      }
      return .latex(id: self.id, content: cleanCode)
    } else {
      return .codeBlock(id: self.id, language: self.language, code: self.code)
    }
  }
}
