import Foundation
import SwiftUI

enum PersonaNode {
    case page(title: String, children: [PersonaNode])
    case h1(String)
    case text(String)
    case canvas(id: String?, mode: String?)
    case returnUI(keywords: [String])
}

struct PersonaParser {
    func parse(_ input: String) -> PersonaNode? {
        var children: [PersonaNode] = []
        var title = ""
        let lines = input.split(separator: "\n")
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("page") {
                if let name = extractQuoted(from: trimmed) {
                    title = name
                }
            } else if trimmed.hasPrefix("H1") {
                if let text = extractQuoted(from: trimmed) {
                    children.append(.h1(text))
                }
            } else if trimmed.hasPrefix("text") {
                if let text = extractQuoted(from: trimmed) {
                    children.append(.text(text))
                }
            } else if trimmed.hasPrefix("canvas") {
                let id = extractAttribute("id", from: trimmed)
                let mode = extractAttribute("mode", from: trimmed)
                children.append(.canvas(id: id, mode: mode))
            } else if trimmed.hasPrefix("returnUI") {
                let keywords = extractKeywords(from: trimmed)
                children.append(.returnUI(keywords: keywords))
            }
        }
        return .page(title: title, children: children)
    }

    private func extractQuoted(from line: String) -> String? {
        guard let range = line.range(of: "\".*?\"", options: .regularExpression) else { return nil }
        let quoted = line[range]
        return String(quoted.dropFirst().dropLast())
    }

    private func extractAttribute(_ name: String, from line: String) -> String? {
        guard let range = line.range(of: "\(name):\".*?\"", options: .regularExpression) else { return nil }
        let substring = line[range]
        return substring.components(separatedBy: "\"")[1]
    }

    private func extractKeywords(from line: String) -> [String] {
        guard let start = line.firstIndex(of: "["), let end = line.firstIndex(of: "]") else { return [] }
        let list = line[line.index(after: start)..<end]
        return list.split(separator: ",").map { $0.replacingOccurrences(of: "\"", with: "").trimmingCharacters(in: .whitespaces) }
    }
}

struct PersonaView: View {
    let node: PersonaNode

    var body: some View {
        switch node {
        case .page(_, let children):
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(children.enumerated()), id: \.offset) { index, child in
                    PersonaView(node: child)
                }
            }
        case .h1(let text):
            Text(text).font(.largeTitle)
        case .text(let text):
            Text(text)
        case .canvas:
            Rectangle().strokeBorder()
        case .returnUI:
            EmptyView()
        }
    }
}
