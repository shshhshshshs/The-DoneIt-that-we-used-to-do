import Foundation
import SQLite3

enum SearchIndexError: Error {
    case open(String)
    case execute(String)
    case prepare(String)
    case step(String)
}

final class SearchIndex {
    private var db: OpaquePointer?

    init(path: URL) throws {
        if sqlite3_open(path.path, &db) != SQLITE_OK {
            let message = String(cString: sqlite3_errmsg(db))
            throw SearchIndexError.open(message)
        }
        let createSQL = """
        CREATE VIRTUAL TABLE IF NOT EXISTS notes USING fts5(id, title, text, keywords);
        """
        if sqlite3_exec(db, createSQL, nil, nil, nil) != SQLITE_OK {
            let message = String(cString: sqlite3_errmsg(db))
            throw SearchIndexError.execute(message)
        }
    }

    deinit {
        if sqlite3_close(db) != SQLITE_OK {
            print("SQLite close error: \(String(cString: sqlite3_errmsg(db)))")
        }
    }

    func index(note: Note) throws {
        let insertSQL = "INSERT INTO notes (id, title, text, keywords) VALUES (?, ?, ?, ?);"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, insertSQL, -1, &stmt, nil) == SQLITE_OK else {
            let message = String(cString: sqlite3_errmsg(db))
            throw SearchIndexError.prepare(message)
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_text(stmt, 1, note.id.uuidString, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 2, note.title, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 3, note.blockTexts(), -1, SQLITE_TRANSIENT)
        let keywords = note.keywords?.joined(separator: " ") ?? ""
        sqlite3_bind_text(stmt, 4, keywords, -1, SQLITE_TRANSIENT)

        if sqlite3_step(stmt) != SQLITE_DONE {
            let message = String(cString: sqlite3_errmsg(db))
            throw SearchIndexError.step(message)
        }
    }

    func search(_ query: String) throws -> [String] {
        var results: [String] = []
        let searchSQL = "SELECT snippet(notes, 2, '[', ']', '…', 10) FROM notes WHERE notes MATCH ?;"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, searchSQL, -1, &stmt, nil) == SQLITE_OK else {
            let message = String(cString: sqlite3_errmsg(db))
            throw SearchIndexError.prepare(message)
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_text(stmt, 1, query, -1, SQLITE_TRANSIENT)
        while true {
            let rc = sqlite3_step(stmt)
            if rc == SQLITE_ROW {
                if let cString = sqlite3_column_text(stmt, 0) {
                    results.append(String(cString: cString))
                }
            } else if rc == SQLITE_DONE {
                break
            } else {
                let message = String(cString: sqlite3_errmsg(db))
                throw SearchIndexError.step(message)
            }
        }
        return results
    }
}
