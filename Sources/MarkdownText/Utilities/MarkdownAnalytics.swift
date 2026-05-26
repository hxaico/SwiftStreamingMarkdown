//
//  Copyright © 2025 Microsoft. All rights reserved.
//

import AsyncExtensions
import Foundation

public protocol MarkdownListener {
  func onRender(markdown: RenderableDocument, metadata: MarkdownMetadata?) async
}

public final class MarkdownController: ObservableObject {

  private let analytics: MarkdownListener?
  private let metadata: MarkdownMetadata?
  private let eventSubject = AsyncCurrentValueSubject<RenderableDocument?>(nil)
  private var analyticsTask: Task<(), Error>!

  public init(analytics: MarkdownListener?, metadata: MarkdownMetadata?) {
    self.analytics = analytics
    self.metadata = metadata
  }

  public func onAppear(markdown: RenderableDocument) {
    guard let analytics else {
      return
    }
    self.analyticsTask = Task {
      for try await md in eventSubject.eraseToAnyAsyncSequence().compactMap({ $0 }) {
        await analytics.onRender(markdown: md, metadata: metadata)
      }
    }
    eventSubject.send(markdown)
  }

  public func onChange(markdown: RenderableDocument) {
    eventSubject.send(markdown)
  }

  public func onDisappear() {
    analyticsTask?.cancel()
  }
}
