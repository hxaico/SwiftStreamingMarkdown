//
//  Copyright © 2025 Microsoft. All rights reserved.
//

//  SnapshotTestCase is a utility class extending XCTestCase.
//
//  By default, it registers a diff tool ("diff-image") to assist in comparing mismatched snapshots.
//  You can toggle recording behavior by setting `isRecording` to `true` or `false` in `setUp()`.
//
//  Bazel Integration:
//  - When running in Bazel, reference images are read from test bundle (included as data)
//  - Failure artifacts (diffs) are written to TEST_UNDECLARED_OUTPUTS_DIR
//  - Recording is disabled in Bazel (source is read-only)
//  - Xcode/SPM behavior is unchanged
//
//  Xcode Version Requirement:
//  - Snapshot tests require a specific Xcode version for consistent rendering
//  - The required version is configured in .bazelrc (SNAPSHOT_XCODE_VERSION env var)
//  - Tests will be skipped if SNAPSHOT_XCODE_VERSION is set but doesn't match current Xcode
//  - See .bazelrc for setup instructions
//
import SnapshotTesting
import SwiftUI
import XCTest

open class SnapshotTestCase: XCTestCase {
  /// Returns true if running in Bazel test environment
  public var isRunningInBazel: Bool {
    // Bazel sets BAZEL_TEST=1 via --test_env, or we can detect via test bundle path
    ProcessInfo.processInfo.environment["BAZEL_TEST"] != nil ||
      Bundle(for: type(of: self)).bundlePath.contains("bazel-out")
  }

  /// Returns the current Xcode version (format: "XX.Y" e.g., "26.1")
  private var currentXcodeVersion: String? {
    // Check XCODE_VERSION_ACTUAL env var (set by Bazel or user)
    // Format: XXYYZZ (e.g., 261100 for 26.1.1, 262000 for 26.2.0)
    if let xcodeVersion = ProcessInfo.processInfo.environment["XCODE_VERSION_ACTUAL"] {
      if xcodeVersion.count >= 4 {
        let major = String(xcodeVersion.prefix(2))
        let minor = String(xcodeVersion.dropFirst(2).prefix(2))
        if let majorInt = Int(major), let minorInt = Int(minor) {
          return "\(majorInt).\(minorInt)"
        }
      }
    }
    return nil
  }

  /// Returns the required Xcode version for snapshot tests (from SNAPSHOT_XCODE_VERSION env var)
  private var requiredXcodeVersion: String? {
    ProcessInfo.processInfo.environment["SNAPSHOT_XCODE_VERSION"]
  }

  /// Returns true if snapshot version check should be skipped (SNAPSHOT_SKIP_VERSION_CHECK=1)
  private var shouldSkipVersionCheck: Bool {
    ProcessInfo.processInfo.environment["SNAPSHOT_SKIP_VERSION_CHECK"] == "1"
  }

  private var shouldRecordSnapshots: Bool {
    ProcessInfo.processInfo.environment["SNAPSHOT_RECORDING"] == "1"
  }

  /// Checks Xcode version and fails if it doesn't match the required version.
  /// Set SNAPSHOT_SKIP_VERSION_CHECK=1 to bypass this check during development.
  private func checkXcodeVersionOrFail(file: StaticString, line: UInt) -> Bool {
    // If skip flag is set, allow tests to run without version check
    if shouldSkipVersionCheck {
      return true
    }

    // If no required version is set, allow tests to run
    guard let required = requiredXcodeVersion else {
      return true
    }

    // If we can't determine current version, allow tests to run
    guard let current = currentXcodeVersion else {
      return true
    }

    // Check if current version matches required version
    let matches = current.hasPrefix(required) || required.hasPrefix(current)
    if !matches {
      XCTFail("""
      Snapshot test requires Xcode \(required).x but running \(current).

      To run snapshot tests:
      1. Install and select Xcode \(required).x:
         xcodes install \(required).1
         xcodes select \(required).1

      2. Install iOS \(required) simulator:
         xcodebuild -downloadPlatform iOS

      To skip this check during development (tests may fail due to rendering differences):
         bazel test --test_env=SNAPSHOT_SKIP_VERSION_CHECK=1 //...
      """, file: file, line: line)
      return false
    }
    return true
  }

  /// Returns true if the current Xcode version matches the required version for snapshots
  /// If no required version is set, returns true (no version check)
  public var isCorrectXcodeVersion: Bool {
    if shouldSkipVersionCheck { return true }
    guard let required = requiredXcodeVersion else { return true }
    guard let current = currentXcodeVersion else { return true }
    return current.hasPrefix(required) || required.hasPrefix(current)
  }

  /// Returns the writable directory for snapshot failure artifacts in Bazel
  private var bazelArtifactsDir: String? {
    // Bazel provides these writable directories during test execution
    // TEST_UNDECLARED_OUTPUTS_DIR is collected after test completion
    ProcessInfo.processInfo.environment["TEST_UNDECLARED_OUTPUTS_DIR"] ??
      ProcessInfo.processInfo.environment["TEST_TMPDIR"]
  }

  /// Returns the snapshot directory to use, handling both Xcode and Bazel environments
  /// - Parameter file: The test file path (from #file)
  /// - Parameter testName: The test function name
  /// - Returns: The directory containing reference snapshots
  private func snapshotDirectory(for file: StaticString, testName: String) -> String? {
    if isRunningInBazel {

      let testClassName = String(describing: type(of: self))
      let filePath = String(describing: file)
      let fileBaseName = URL(fileURLWithPath: filePath).deletingPathExtension().lastPathComponent
      let snapshotSubdirNames = Array(Set([testClassName, fileBaseName])).sorted()

      if shouldRecordSnapshots, let artifactsDir = bazelArtifactsDir {
        let baseDir = URL(fileURLWithPath: artifactsDir)
          .appendingPathComponent("__Snapshots__")
          .appendingPathComponent(fileBaseName)
        try? FileManager.default.createDirectory(at: baseDir, withIntermediateDirectories: true)
        return baseDir.path
      }

      // In Bazel, snapshots are included as a resource bundle in test data
      // Look for the snapshot bundle in various locations
      let testBundle = Bundle(for: type(of: self))

      // Method 1: Look for *Snapshots.bundle in the test bundle
      if let resourcePath = testBundle.resourcePath {
        let resourceURL = URL(fileURLWithPath: resourcePath)
        if let contents = try? FileManager.default.contentsOfDirectory(at: resourceURL, includingPropertiesForKeys: nil) {
          for url in contents where url.lastPathComponent.contains("Snapshots") && url.pathExtension == "bundle" {
            // Found a snapshots bundle
            // Check for test-class or test-file-named subdirectory (e.g., TabBarSnapshotTests/)
            for subdirName in snapshotSubdirNames {
              let classSubdir = url.appendingPathComponent(subdirName)
              if FileManager.default.fileExists(atPath: classSubdir.path) {
                return classSubdir.path
              }
            }

            // Check for __Snapshots__/TestClassName or __Snapshots__/TestFileName structure
            for subdirName in snapshotSubdirNames {
              let snapshotsSubdir = url.appendingPathComponent("__Snapshots__").appendingPathComponent(subdirName)
              if FileManager.default.fileExists(atPath: snapshotsSubdir.path) {
                return snapshotsSubdir.path
              }
            }

            // Fallback: search recursively for any __Snapshots__/TestClassName within the bundle
            if let enumerator = FileManager.default.enumerator(
              at: url,
              includingPropertiesForKeys: [.isDirectoryKey],
              options: [.skipsHiddenFiles]
            ) {
              for case let itemURL as URL in enumerator where itemURL.lastPathComponent == "__Snapshots__" {
                for subdirName in snapshotSubdirNames {
                  let classDir = itemURL.appendingPathComponent(subdirName)
                  if FileManager.default.fileExists(atPath: classDir.path) {
                    return classDir.path
                  }
                }
              }
            }

            // Fallback: use the bundle directly (flat structure)
            return url.path
          }
        }
      }

      // Method 2: Try to find __Snapshots__/TestClassName in the bundle's resource path
      if let resourcePath = testBundle.resourcePath {
        let snapshotsPath = (resourcePath as NSString)
          .appendingPathComponent("__Snapshots__")
        for subdirName in snapshotSubdirNames {
          let classPath = (snapshotsPath as NSString).appendingPathComponent(subdirName)
          if FileManager.default.fileExists(atPath: classPath) {
            return classPath
          }
        }
        if FileManager.default.fileExists(atPath: snapshotsPath) {
          return snapshotsPath
        }
      }

      // If no snapshots found in bundle, return nil (will use default behavior which may fail)
      return nil
    } else {
      // In Xcode/SPM: use default behavior (nil means swift-snapshot-testing uses #file-based path)
      return nil
    }
  }

  override open func setUp() {
    super.setUp()
    SnapshotTesting.diffTool = "diff-image"

    if isRunningInBazel {
      // In Bazel: default to disable recording (source is read-only)
      isRecording = shouldRecordSnapshots

      // Configure failure artifacts to go to Bazel's writable output directory
      if let artifactsDir = bazelArtifactsDir {
        // Set environment variable that swift-snapshot-testing uses for failure artifacts
        setenv("SNAPSHOT_ARTIFACTS", artifactsDir, 1)
      }
    } else if shouldRecordSnapshots {
      isRecording = true
    }
    // isRecording = true
  }

  /// Skips the current test if running in Bazel environment where snapshot tests can't write files
  public func skipInBazel(_ message: String = "Snapshot tests are skipped in Bazel due to read-only source directory") throws {
    try XCTSkipIf(isRunningInBazel, message)
  }

  /* Function to perform snapshot tests. Embeds all views in a ViewController for.
   - Parameters:
   - view: View to be tested
   - variants: Device variants to be tested. Defaults to the standard collection of device variants
   - testName: The name of the test in which failure occurred. Defaults to the function name of the test case in which this function was called.
   - file: The file in which failure occurred. Defaults to the file name of the test case in which this function was called.
   - line: The line number on which failure occurred. Defaults to the line number on which this function was called.
   */

  public func assert<V: View>(
    _ view: V,
    variants: [DeviceVariant] = .standard(precision: 0.99, perceptualPrecision: 1.00),
    testName: String = #function,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    // Check Xcode version - fail if required version is set and doesn't match
    guard checkXcodeVersionOrFail(file: file, line: line) else { return }

    let snapshotDir = snapshotDirectory(for: file, testName: testName)

    variants.forEach { variant in
      // Use verifySnapshot when we need custom snapshotDirectory (Bazel), otherwise use assertSnapshot
      if let snapshotDir = snapshotDir {
        let failure = verifySnapshot(
          of: view.environment(\.colorScheme, variant.colorScheme).asViewController,
          as: variant.snapshot,
          named: variant.name,
          snapshotDirectory: snapshotDir,
          file: file,
          testName: testName,
          line: line
        )
        if let failure = failure {
          XCTFail(failure, file: file, line: line)
        }
      } else {
        assertSnapshot(
          of: view.environment(\.colorScheme, variant.colorScheme).asViewController,
          as: variant.snapshot,
          named: variant.name,
          file: file,
          testName: testName,
          line: line
        )
      }
    }
  }

  public func assert(
    _ view: UIView,
    variants: [DeviceVariant] = .standard(precision: 0.99, perceptualPrecision: 1.00),
    testName: String = #function,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    assert(
      view.asView,
      variants: variants,
      testName: testName,
      file: file,
      line: line)
  }

  /// Snapshots for only iPhone
  public func assertIPhone<V: View>(
    _ view: V,
    height: CGFloat? = nil,
    precision: Float = 0.99,
    perceptualPrecision: Float = 1.00,
    testName: String = #function,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    assert(
      view,
      variants: .iPhoneOnly(height: height, precision: precision, perceptualPrecision: perceptualPrecision),
      testName: testName,
      file: file,
      line: line
    )
  }

  /// Snapshots for only iPad
  public func assertIPad<V: View>(
    _ view: V,
    height: CGFloat? = nil,
    precision: Float = 0.99,
    perceptualPrecision: Float = 1.00,
    testName: String = #function,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    assert(
      view,
      variants: .iPadOnly(height: height, precision: precision, perceptualPrecision: perceptualPrecision),
      testName: testName,
      file: file,
      line: line
    )
  }

  /// Snapshot a UIView at a fixed width with content-driven height, in both light and dark themes.
  /// Produces component-only snapshots (no device chrome) suitable for cross-platform comparison.
  public func assertCompact(
    _ view: UIView,
    width: CGFloat = 360,
    precision: Float = 0.99,
    perceptualPrecision: Float = 0.96,
    testName: String = #function,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    // Check Xcode version
    guard checkXcodeVersionOrFail(file: file, line: line) else { return }

    // Measure content height at the given width
    view.frame = CGRect(x: 0, y: 0, width: width, height: 0)
    view.sizeToFit()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.widthAnchor.constraint(equalToConstant: width).isActive = true
    view.layoutIfNeeded()
    let contentHeight = max(view.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height, 20)
    let snapshotSize = CGSize(width: width, height: contentHeight.rounded(.up))

    let snapshotDir = snapshotDirectory(for: file, testName: testName)
    let themes: [(ColorScheme, String)] = [(.light, "light"), (.dark, "dark")]
    for (colorScheme, themeName) in themes {
      let wrapper = view.asView
        .frame(width: snapshotSize.width, height: snapshotSize.height)
        .background(colorScheme == .dark ? Color.black : Color.white)
        .environment(\.colorScheme, colorScheme)

      let vc = UIHostingController(rootView: wrapper)
      vc.view.frame = CGRect(origin: .zero, size: snapshotSize)

      let strategy: Snapshotting<UIViewController, UIImage> = .image(
        precision: precision,
        perceptualPrecision: perceptualPrecision,
        size: snapshotSize
      )

      if let snapshotDir = snapshotDir {
        let failure = verifySnapshot(
          of: vc,
          as: strategy,
          named: themeName,
          snapshotDirectory: snapshotDir,
          file: file,
          testName: testName,
          line: line
        )
        if let failure = failure {
          XCTFail(failure, file: file, line: line)
        }
      } else {
        assertSnapshot(
          of: vc,
          as: strategy,
          named: themeName,
          file: file,
          testName: testName,
          line: line
        )
      }
    }
  }

  /// Test views with no device specified
  public func assertNoDevice<V: View>(
    _ view: V,
    testName: String = #function,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    // Check Xcode version - fail if required version is set and doesn't match
    guard checkXcodeVersionOrFail(file: file, line: line) else { return }

    let snapshotDir = snapshotDirectory(for: file, testName: testName)

    // Use verifySnapshot when we need custom snapshotDirectory (Bazel), otherwise use assertSnapshot
    if let snapshotDir = snapshotDir {
      let failure = verifySnapshot(
        of: view.asViewController,
        as: .image(),
        named: "List",
        snapshotDirectory: snapshotDir,
        file: file,
        testName: testName,
        line: line
      )
      if let failure = failure {
        XCTFail(failure, file: file, line: line)
      }
    } else {
      assertSnapshot(
        of: view.asViewController,
        as: .image(),
        named: "List",
        file: file,
        testName: testName,
        line: line
      )
    }
  }
}

private extension UIView {
  struct SwiftUIViewController: UIViewControllerRepresentable {
    private let rootView: UIView

    init(rootView: UIView) {
      self.rootView = rootView
    }

    func makeUIViewController(context: Context) -> ViewController {
      ViewController(rootView: rootView)
    }

    func updateUIViewController(_ uiViewController: ViewController, context: Context) {
      // N/A
    }
  }

  final class ViewController: UIViewController {
    private let rootView: UIView
    init(rootView: UIView) {
      self.rootView = rootView
      super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
      super.viewDidLoad()

      rootView.removeFromSuperview()
      view.addSubview(rootView)
      rootView.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        rootView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        rootView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        rootView.topAnchor.constraint(equalTo: view.topAnchor),
        rootView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
      ])
    }
  }

  var asView: some View {
    SwiftUIViewController(rootView: self)
  }
}

private extension View {
  var asViewController: UIViewController {
    let vc = UIHostingController(rootView: self)
    vc.view.backgroundColor = .clear
    return vc
  }
}
