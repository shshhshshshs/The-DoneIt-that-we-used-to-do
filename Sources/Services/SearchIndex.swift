import Foundation
import SQLite3

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
private let SQLITE_STATIC    = unsafeBitCast(0,  to: sqlite3_destructor_type.self)

@inline(__always)
private func bindText(_ stmt: OpaquePointer?, _ idx: Int32, _ s: String) {
    s.withCString { cstr in
        sqlite3_bind_text(stmt, idx, cstr, -1, SQLITE_TRANSIENT)
    }
}

final class SearchIndex {
    private var db: OpaquePointer?

    init(path: URL) {
        let dbURL = path.appendingPathComponent("search.sqlite")
        sqlite3_open(dbURL.path, &db)
        let createSQL = """
        CREATE VIRTUAL TABLE IF NOT EXISTS notes USING fts5(title, text, keywords, tokenize='unicode61');
        """
        sqlite3_exec(db, createSQL, nil, nil, nil)
    }

    deinit {
        sqlite3_close(db)
    }

    func upsert(id: Int64, title: String, text: String, keywords: String) {
        let sql = """
        INSERT INTO notes(rowid, title, text, keywords)
        VALUES(?, ?, ?, ?)
        ON CONFLICT(rowid) DO UPDATE SET title=excluded.title, text=excluded.text, keywords=excluded.keywords;
        """
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int64(stmt, 1, id)
            bindText(stmt, 2, title)
            bindText(stmt, 3, text)
            bindText(stmt, 4, keywords)
            sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
    }

    func search(_ q: String, limit: Int) -> [(Int64, String)] {
        var results: [(Int64, String)] = []
        let sql = "SELECT rowid, snippet(notes, 1, '[', ']', '…', 10) FROM notes WHERE notes MATCH ? LIMIT ?;"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            bindText(stmt, 1, q)
            sqlite3_bind_int(stmt, 2, Int32(limit))
            while sqlite3_step(stmt) == SQLITE_ROW {
                let rowid = sqlite3_column_int64(stmt, 0)
                if let cString = sqlite3_column_text(stmt, 1) {
                    results.append((rowid, String(cString: cString)))
                }
            }
        }
        sqlite3_finalize(stmt)
        return results
    }
}
