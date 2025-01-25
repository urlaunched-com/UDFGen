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
    
    // Extract module name
    let moduleName: String
    if let moduleNameIndex = arguments.firstIndex(of: "--name"), arguments.count > moduleNameIndex + 1 {
        moduleName = arguments[moduleNameIndex + 1]
    } else {
        moduleName = defaultModuleName
    }
    
    var modulePath: String
    
    // Check if user wants to find a specific folder
    if let findFolderIndex = arguments.firstIndex(of: "--find-folder"), arguments.count > findFolderIndex + 1 {
        let folderToFind = arguments[findFolderIndex + 1]
        if let foundPath = findFolder(named: folderToFind, in: basePath) {
            modulePath = "\(foundPath)/\(moduleName)"
        } else {
            throw NSError(domain: "PluginError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Error: Folder '\(folderToFind)' not found in project."])
        }
    }
    // Check if user specified a path
    else if let pathIndex = arguments.firstIndex(of: "--path"), arguments.count > pathIndex + 1 {
        modulePath = "\(basePath)/\(arguments[pathIndex + 1])/\(moduleName)"
    }
    // Default to project root if no path is specified
    else {
        modulePath = "\(basePath)/\(moduleName)"
    }
    
    writeUDFTemplate(to: modulePath, moduleName: moduleName)
}

private func findFolder(named folderName: String, in basePath: String) -> String? {
    let fileManager = FileManager.default
    let enumerator = fileManager.enumerator(atPath: basePath)
    
    while let element = enumerator?.nextObject() as? String {
        if element.hasSuffix(folderName) {
            return "\(basePath)/\(element)"
        }
    }
    
    return nil
}

private func writeUDFTemplate(to modulePath: String, moduleName: String ) {
    let fileManager = FileManager.default
    
    do {
        try fileManager.createDirectory(atPath: modulePath, withIntermediateDirectories: true, attributes: nil)
    } catch {
        print("Error: Failed to create module directory at '\(modulePath)'. \(error.localizedDescription)")
        return
    }
    
    let files = [
        "View/\(moduleName)Container.swift": "// \(moduleName)Container",
        "View/\(moduleName)Component.swift": "// \(moduleName)Component",
        "State/\(moduleName)Flow.swift": "// \(moduleName)Flow",
        "State/\(moduleName)Form.swift": "// \(moduleName)Form",
        "\(moduleName)Middleware.swift": "// \(moduleName)Middleware"
    ]
    
    for (filePath, content) in files {
        let fullFilePath = "\(modulePath)/\(filePath)"
        let directory = (fullFilePath as NSString).deletingLastPathComponent
        
        do {
            try fileManager.createDirectory(atPath: directory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Error: Failed to create directory for file '\(fullFilePath)'. \(error.localizedDescription)")
            continue
        }
        
        do {
            try content.write(toFile: fullFilePath, atomically: true, encoding: .utf8)
        } catch {
            print("Error: Failed to write content to file '\(fullFilePath)'. \(error.localizedDescription)")
            continue
        }
    }
    
    print("Module '\(moduleName)' successfully generated at: \(modulePath)")
}
