//
//  StringExtensions.swift
//  SEN55gpsapp012
//
//  Created by Szamosi Attila on 2025. 01. 11..
import Foundation

extension String {
    // Szálbiztos soros queue a fájlba íráshoz
    private static let fileWriteQueue = DispatchQueue(label: "com.example.fileWriteQueue", qos: .utility)

    func appendLineToURL(fileURL: URL) throws {
        // A sor végére új sort adunk, majd meghívjuk az appendToURL-t
        try (self + "\n").appendToURL(fileURL: fileURL)
    }

    func appendToURL(fileURL: URL) throws {
        // Szinkron írás a fájlba a soros queue-n keresztül
        try String.fileWriteQueue.sync {
            // Ellenőrizzük, hogy a fájl írható-e, vagy még nem létezik
            guard FileManager.default.isWritableFile(atPath: fileURL.path) || !FileManager.default.fileExists(atPath: fileURL.path) else {
                throw NSError(domain: "StringExtension", code: -2, userInfo: [NSLocalizedDescriptionKey: "A fájl nem írható: \(fileURL.path)"])
            }

            // A stringet UTF-8 adatra konvertáljuk
            guard let data = self.data(using: .utf8) else {
                throw NSError(domain: "StringExtension", code: -1, userInfo: [NSLocalizedDescriptionKey: "Nem sikerült a stringet UTF-8 adatra konvertálni."])
            }

            // Ha a fájl létezik, hozzáfűzünk, különben új fájlt hozunk létre
            if FileManager.default.fileExists(atPath: fileURL.path) {
                do {
                    let fileHandle = try FileHandle(forWritingTo: fileURL)
                    defer { fileHandle.closeFile() }
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                } catch {
                    throw error // A hibát továbbdobjuk
                }
            } else {
                do {
                    try data.write(to: fileURL, options: .atomic)
                } catch {
                    throw error // A hibát továbbdobjuk
                }
            }
        }
    }
}
