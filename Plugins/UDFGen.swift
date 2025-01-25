import PackagePlugin
import Foundation

@main
struct UDFGen: CommandPlugin {
    // Entry point for Swift Package command plugin
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        try generateModule(basePath: context.package.directory.string, arguments: arguments)
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension UDFGen: XcodeCommandPlugin {
    // Entry point for Xcode command plugin
    func performCommand(context: XcodePluginContext, arguments: [String]) throws {
        try generateModule(basePath: context.xcodeProject.directory.string, arguments: arguments)
    }
}
#endif

// Common function for both command plugin contexts
private func generateModule(basePath: String, arguments: [String]) throws {
    let defaultModuleName = "NewModule"
    
    // Check if --name argument exists and has a valid value, otherwise use default
    let moduleName: String
    if let moduleNameIndex = arguments.firstIndex(of: "--name"), arguments.count > moduleNameIndex + 1 {
        moduleName = arguments[moduleNameIndex + 1]
    } else {
        moduleName = defaultModuleName
    }
    
    let modulePath = "\(basePath)/\(moduleName)"
    
    // Create the module folder structure
    let fileManager = FileManager.default
    try fileManager.createDirectory(atPath: modulePath, withIntermediateDirectories: true, attributes: nil)

    let files = [
        "View/\(moduleName)Container.swift": "\(moduleName)Container",
        "View/\(moduleName)Component.swift": "\(moduleName)Component",
        "State/\(moduleName)Flow.swift": "\(moduleName)Flow",
        "State/\(moduleName)Form.swift": "\(moduleName)Form",
        "\(moduleName)Middleware.swift": "\(moduleName)Middleware"
    ]

    for (filePath, content) in files {
        let fullFilePath = "\(modulePath)/\(filePath)"
        let directory = (fullFilePath as NSString).deletingLastPathComponent
        try fileManager.createDirectory(atPath: directory, withIntermediateDirectories: true, attributes: nil)
        try content.write(toFile: fullFilePath, atomically: true, encoding: .utf8)
    }

    print("Module '\(moduleName)' successfully generated at: \(modulePath)")
}
