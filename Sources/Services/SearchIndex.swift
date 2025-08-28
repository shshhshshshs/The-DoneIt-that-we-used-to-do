import Foundation
import SQLite3

final class SearchIndex {
    private var db: OpaquePointer?

    init(path: URL, existingNotes: [Note] = []) {
        sqlite3_open(path.path, &db)
        rebuild(with: existingNotes)
    }

    deinit {
        sqlite3_close(db)
    }

    /// Rebuilds the full-text search table using an n-gram tokenizer and
    /// reindexes the provided notes.
    /// - Parameter notes: Existing notes to be reindexed after rebuilding.
    func rebuild(with notes: [Note]) {
        sqlite3_exec(db, "DROP TABLE IF EXISTS notes;", nil, nil, nil)
        let createSQL = """
        CREATE VIRTUAL TABLE notes USING fts5(
            id, title, text, keywords,
            tokenize='unicode61 remove_diacritics 2'
        );
        """
        sqlite3_exec(db, createSQL, nil, nil, nil)
        notes.forEach { index(note: $0) }
    }

    func index(note: Note) {
        let insertSQL = "INSERT INTO notes (id, title, text, keywords) VALUES (?, ?, ?, ?);"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, insertSQL, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, note.id.uuidString, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(stmt, 2, note.title, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(stmt, 3, note.blockTexts(), -1, SQLITE_TRANSIENT)
            let keywords = note.keywords?.joined(separator: " ") ?? ""
            sqlite3_bind_text(stmt, 4, keywords, -1, SQLITE_TRANSIENT)
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
