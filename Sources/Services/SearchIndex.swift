import Foundation
import SQLite3

final class SearchIndex {
    private var db: OpaquePointer?

    init(path: URL) {
        sqlite3_open(path.path, &db)
        let createSQL = """
        CREATE VIRTUAL TABLE IF NOT EXISTS notes USING fts5(id, title, text, keywords);
        """
        sqlite3_exec(db, createSQL, nil, nil, nil)
    }

    deinit {
        sqlite3_close(db)
    }

    func upsert(id: String, title: String, text: String, keywords: [String]) {
        let upsertSQL = "INSERT OR REPLACE INTO notes (id, title, text, keywords) VALUES (?, ?, ?, ?);"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, upsertSQL, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, id, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(stmt, 2, title, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(stmt, 3, text, -1, SQLITE_TRANSIENT)
            let keywordsString = keywords.joined(separator: " ")
            sqlite3_bind_text(stmt, 4, keywordsString, -1, SQLITE_TRANSIENT)
            sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
    }

    func search(_ query: String) -> [String] {
        var results: [String] = []
        let searchSQL = "SELECT snippet(notes, 2, '[', ']', '…', 10) FROM notes WHERE notes MATCH ?;"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, searchSQL, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, query, -1, SQLITE_TRANSIENT)
            while sqlite3_step(stmt) == SQLITE_ROW {
                if let cString = sqlite3_column_text(stmt, 0) {
                    results.append(String(cString: cString))
                }
            }
        }
        sqlite3_finalize(stmt)
        return results
    }
}
