//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import Foundation

extension CodeBlockView {

  static let syntaxHighlightingCss = """
  code {
  color: #FCFAF7
  }

  .hljs-comment,
  .hljs-meta {
  color: #AA9C87
  }

  .hljs-built_in,
  .hljs-class .hljs-title {
  color: #FFC42F
  }

  .hljs-doctag,
  .hljs-formula,
  .hljs-keyword,
  .hljs-literal {
  color: #67ABF1
  }
  .hljs-addition,
  .hljs-attribute,
  .hljs-meta-string,
  .hljs-regexp,
  .hljs-string {
  color: #00B360
  }
  .hljs-attr,
  .hljs-number,
  .hljs-selector-attr,
  .hljs-selector-class,
  .hljs-selector-pseudo,
  .hljs-template-variable,
  .hljs-type,
  .hljs-variable {
  color: #F96C00
  }

  .hljs-bullet,
  .hljs-link,
  .hljs-selector-id,
  .hljs-symbol,
  .hljs-title {
  color: #E3B5FA
  }
  """
}
