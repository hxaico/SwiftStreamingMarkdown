//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import Foundation
import HighlightSwift
import SwiftUI

struct CodeBlockView: View {
  @Environment(\.markdownConfig) private var config: MarkdownRenderConfig
  @Environment(\.colorScheme) private var colorScheme

  let language: String
  let code: String
  let onCodeCopied: (() -> Void)?

  @State var copied: Bool = false
  @State var attributedString: AttributedString?
  @StateObject private var taskManager: HighlightTaskManager = HighlightTaskManager()

  init(language: String, code: String, onCodeCopied: (() -> Void)? = nil) {
    self.language = language
    self.code = code
    self.onCodeCopied = onCodeCopied
  }

  private func updateAttributedString(code: String, scheme: ColorScheme) async {
    let colors = config.codeBlockConfig.theme.highlightColors(for: scheme)
    await taskManager.enqueueCode(code, colors: colors) { newAttributedString in
      self.attributedString = newAttributedString
    }
  }

  private var backgroundColor: Color? {
    config.codeBlockConfig.backgroundColor
  }

  private var foregroundColor: Color {
    config.codeBlockConfig.foregroundColor ?? Color.Static.Stone.Stone350
  }

  private var cornerRadius: CGFloat {
    config.codeBlockConfig.cornerRadius ?? 20
  }

  private var codeBlockFonts: TextFonts {
    config.codeBlockConfig.textFonts ?? Typography.codeTextFonts
  }

  private var codeBlockTextColor: Color {
    config.codeBlockConfig.textColor ?? Color.Theme.Foreground.Primary.Primary750
  }

  @ViewBuilder
  var codeblock: some View {
    ScrollView(.horizontal) {
      Group {
        if #available(iOS 16.1, *) {  // Minimum version for HighlightSwift
          if let attributed = attributedString {
            Text(attributed)
              .transition(.opacity)
          } else {
            Text(code)
              .foregroundStyle(codeBlockTextColor)
              .transition(.opacity)
          }
        } else {
          Text(code)
            .foregroundStyle(codeBlockTextColor)
            .transition(.opacity)
        }
      }
      .font(codeBlockFonts)
      .multilineTextAlignment(.leading)
    }
    .fixedSize(horizontal: false, vertical: true)
    .transaction { transaction in
      // The horizontal scrollView resizing animation was causing the code block to animate
      // all janky.
      transaction.animation = nil
    }
    .onSizeChange { size in
      MathRenderDiagnostics.logCodeBlockLayoutIfInteresting(
        source: "codeblock/layout",
        language: language,
        code: code,
        size: size
      )
    }
    .padding(16)
  }

  var body: some View {
    VStack(spacing: 0) {
      HStack(alignment: .top) {
        Text(language)
          .font(Typography.smallTextFonts)
          .foregroundStyle(foregroundColor)
        Spacer()
        HStack(alignment: .firstTextBaseline, spacing: 6.0) {
          Image("copyIcon14", bundle: .module)
            .renderingMode(.template)
            .foregroundStyle(foregroundColor)
          Text(copied ? String.codeCopiedLabel : String.codeCopyLabel)
            .accessibilityAddTraits(.isButton)
            .font(Typography.smallTextFonts)
            .foregroundStyle(foregroundColor)
            .onTapGesture {
              copied = true
              #if canImport(UIKit)
              UIPasteboard.general.string = code
              #elseif canImport(AppKit)
              NSPasteboard.general.clearContents()
              NSPasteboard.general.setString(code, forType: .string)
              #endif
              if let onCodeCopied {
                onCodeCopied()
              }
            }
        }
      }.frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .if(backgroundColor != nil, content: { view in
          view.codeBlockBackground(color: backgroundColor ?? .clear, radius: cornerRadius, topRounded: true, bottomRounded: false)
        })
      codeblock
        .scrollIndicators(.automatic)
        .if(backgroundColor != nil, content: { view in
          view.codeBlockBackground(color: backgroundColor ?? .clear, radius: cornerRadius, topRounded: false, bottomRounded: true)
        })
    }.onChange(of: copied, perform: { isCopied in
      if isCopied {
        Task {
          try await Task.sleep(seconds: 3)
          copied = false
        }
      }
    })
    .onChange(of: code, perform: { value in
      Task {
        await updateAttributedString(code: value, scheme: colorScheme)
      }
    })
    .onChange(of: colorScheme, perform: { newValue in
      Task {
        await updateAttributedString(code: code, scheme: newValue)
      }
    })
    .onChange(of: config, perform: { _ in
      Task {
        await updateAttributedString(code: code, scheme: colorScheme)
      }
    })
    .onAppear(perform: {
      Task {
        await updateAttributedString(code: code, scheme: colorScheme)
      }
    })
  }
}

private extension View {
  func codeBlockBackground(
    color: Color,
    radius: CGFloat,
    topRounded: Bool,
    bottomRounded: Bool
  ) -> some View {
    self.background(
      color.clipShape(.rect(
        topLeadingRadius: topRounded ? radius : 0,
        bottomLeadingRadius: bottomRounded ? radius : 0,
        bottomTrailingRadius: bottomRounded ? radius : 0,
        topTrailingRadius: topRounded ? radius : 0
      ))
    )
  }
}

#if DEBUG

#Preview {
  return LazyVStack {
    Spacer()
    CodeBlockView(language: "Python", code: "import random\n\ndef generate_and_add_numbers(num_numbers):\n    # Generate a list of random numbers random_numbers\n    random_numbers = [random.randint(1, 100) for _ in range(num_numbers)]\n\n\n    # Add the numbers together\n    sum_of_numbers = sum(random_numbers)\n\n    return random_numbers, sum_of_numbers\n\n# Example: Generate 5 random numbers and add them together\nnum_numbers = 5\nrandom_numbers, sum_of_numbers = generate_and_add_numbers(num_numbers)\nprint(f\"Generated numbers: {random_numbers}\")\nprint(f\"Sum of numbers: {sum_of_numbers}\")")
    Spacer()
  }.padding(24)
}

#endif
