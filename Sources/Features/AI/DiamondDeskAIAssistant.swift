import Foundation

struct DiamondDeskAIAssistant {
    static func main() async {
        do {
            let args = Array(CommandLine.arguments.dropFirst())
            let rootURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            let assistant = DiamondDeskAI(rootURL: rootURL)
            try await assistant.run(arguments: args)
        } catch {
            print("Error: \(error.localizedDescription)")
            exit(1)
        }
    }
}

struct DiamondDeskAI {
    let rootURL: URL
    let logFileName = "diamondDeskAI.log"
    var logURL: URL { rootURL.appendingPathComponent(logFileName) }
    
    func run(arguments: [String]) async throws {
        let command = try parseCommand(from: arguments)
        var log = try loadLog()
        
        let openAI = OpenAI()
        
        switch command {
        case .help:
            printHelp()
        case .list:
            try listCommands()
        case .run(let cmd):
            log = try await runCommand(cmd, log: log, openAI: openAI)
        }
        
        try saveLog(log)
    }
    
    enum Command {
        case help
        case list
        case run(String)
    }
    
    func parseCommand(from arguments: [String]) throws -> Command {
        guard let first = arguments.first else {
            return .help
        }
        
        switch first {
        case "--help", "-h":
            return .help
        case "--list", "-l":
            return .list
        case "--run", "-r":
            guard arguments.count > 1 else {
                throw NSError(domain: "DiamondDeskAI", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing command to run"])
            }
            return .run(arguments[1])
        default:
            throw NSError(domain: "DiamondDeskAI", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unknown argument \(first)"])
        }
    }
    
    func printHelp() {
        let helpText = """
        DiamondDeskAI - AI assistant for DiamondDesk
        
        Usage:
          --help, -h       Show this help message
          --list, -l       List available commands
          --run, -r CMD    Run the specified command
        
        """
        print(helpText)
    }
    
    func listCommands() throws {
        let commandsURL = rootURL.appendingPathComponent("Commands")
        let items = try FileManager.default.contentsOfDirectory(atPath: commandsURL.path)
        let commandFiles = items.filter { $0.hasSuffix(".swift") }
        print("Available commands:")
        for file in commandFiles {
            print("- \(file.replacingOccurrences(of: ".swift", with: ""))")
        }
    }
    
    func runCommand(_ command: String, log: [String], openAI: OpenAI) async throws -> [String] {
        var updatedLog = log
        updatedLog.append("Running command: \(command)")
        print("Running command: \(command)")
        
        let commandsURL = rootURL.appendingPathComponent("Commands")
        let commandFileURL = commandsURL.appendingPathComponent("\(command).swift")
        
        guard FileManager.default.fileExists(atPath: commandFileURL.path) else {
            print("Command \(command) not found.")
            return updatedLog
        }
        
        let code = try String(contentsOf: commandFileURL)
        
        // Prepare prompt with code and previous log
        var prompt = "You are DiamondDesk AI assistant. Execute the following Swift code:\n\n"
        prompt += code
        prompt += "\n\nPrevious log:\n"
        prompt += updatedLog.joined(separator: "\n")
        
        let response = try await openAI.sendPrompt(prompt)
        
        updatedLog.append("Response: \(response)")
        print("AI Response:\n\(response)")
        
        return updatedLog
    }
    
    func loadLog() throws -> [String] {
        if FileManager.default.fileExists(atPath: logURL.path) {
            let content = try String(contentsOf: logURL)
            return content.components(separatedBy: "\n").filter { !$0.isEmpty }
        }
        return []
    }
    
    func saveLog(_ log: [String]) throws {
        let content = log.joined(separator: "\n")
        try content.write(to: logURL, atomically: true, encoding: .utf8)
    }
}

struct OpenAI {
    func sendPrompt(_ prompt: String) async throws -> String {
        // Placeholder for OpenAI integration logic.
        // For this example, just echo prompt.
        return "Simulated AI response for prompt of length \(prompt.count)"
    }
}
