import Foundation
import zlib

// MARK: - XLSX Data Models

public struct XLSXCell {
    public let reference: String // e.g. "A1", "B20"
    public let rowIndex: Int     // 1-indexed
    public let columnIndex: Int  // 1-indexed
    public let value: String?
    public let rawValue: String?
    public let formula: String?
    public let isSharedString: Bool
    
    public var decimalValue: Decimal? {
        guard let val = value else { return nil }
        let clean = val.replacingOccurrences(of: "$", with: "")
                       .replacingOccurrences(of: ",", with: "")
                       .trimmingCharacters(in: .whitespaces)
        return Decimal(string: clean)
    }
    
    public var dateValue: Date? {
        guard let raw = rawValue, let serial = Double(raw) else { return nil }
        // Excel serial date to Swift Date
        // 25569 is the number of days between Jan 1, 1900 and Jan 1, 1970
        let secondsPerDay: Double = 86400.0
        let unixTimestamp = (serial - 25569.0) * secondsPerDay
        return Date(timeIntervalSince1970: unixTimestamp)
    }
}

public struct XLSXSheet {
    public let name: String
    public let targetPath: String
    public let cells: [String: XLSXCell] // Keyed by reference e.g. "B4"
    public let maxRow: Int
    public let maxColumn: Int
    
    public func cell(at ref: String) -> XLSXCell? {
        return cells[ref.uppercased()]
    }
    
    public func cell(row: Int, column: Int) -> XLSXCell? {
        let ref = XLSXSheet.cellReference(row: row, column: column)
        return cells[ref]
    }

    public static func cellReference(row: Int, column: Int) -> String {
        var colStr = ""
        var tempCol = column
        while tempCol > 0 {
            let mod = (tempCol - 1) % 26
            colStr = String(UnicodeScalar(65 + mod)!) + colStr
            tempCol = (tempCol - 1) / 26
        }
        return "\(colStr)\(row)"
    }
    
    public static func columnAndRow(from ref: String) -> (column: Int, row: Int)? {
        let uppercaseRef = ref.uppercased()
        let letters = uppercaseRef.prefix(while: { $0 >= "A" && $0 <= "Z" })
        let numbers = uppercaseRef.suffix(from: letters.endIndex)
        
        guard !letters.isEmpty, let row = Int(numbers), row > 0 else { return nil }
        
        var col = 0
        for char in letters {
            if let ascii = char.asciiValue {
                col = col * 26 + Int(ascii - 64)
            }
        }
        return (col, row)
    }
}

public struct XLSXWorkbook {
    public let sheets: [XLSXSheet]
    public let sheetMap: [String: XLSXSheet]
    
    public init(sheets: [XLSXSheet]) {
        self.sheets = sheets
        var map: [String: XLSXSheet] = [:]
        for sheet in sheets {
            map[sheet.name] = sheet
        }
        self.sheetMap = map
    }
    
    public func sheet(named name: String) -> XLSXSheet? {
        return sheetMap[name]
    }
}

// MARK: - Lightweight Pure Swift ZIP Reader

private struct ZipEntry {
    let fileName: String
    let compressedSize: Int
    let uncompressedSize: Int
    let compressionMethod: UInt16
    let localHeaderOffset: UInt32
}

private class SimpleZipUnpacker {
    let data: Data
    
    init(data: Data) {
        self.data = data
    }
    
    func readEntries() -> [String: ZipEntry] {
        var entries: [String: ZipEntry] = [:]
        var offset = data.count - 22
        
        while offset > 0 {
            let sig = data.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: offset, as: UInt32.self) }
            if sig == 0x06054b50 { break }
            offset -= 1
        }
        guard offset > 0 else { return [:] }
        
        let cdOffset = Int(data.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: offset + 16, as: UInt32.self) })
        let cdCount = Int(data.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: offset + 10, as: UInt16.self) })
        
        var currentCD = cdOffset
        for _ in 0..<cdCount {
            guard currentCD + 46 <= data.count else { break }
            let sig = data.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: currentCD, as: UInt32.self) }
            if sig != 0x02014b50 { break }
            
            let method = data.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: currentCD + 10, as: UInt16.self) }
            let compSize = Int(data.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: currentCD + 20, as: UInt32.self) })
            let uncompSize = Int(data.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: currentCD + 24, as: UInt32.self) })
            let nameLen = Int(data.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: currentCD + 28, as: UInt16.self) })
            let extraLen = Int(data.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: currentCD + 30, as: UInt16.self) })
            let commentLen = Int(data.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: currentCD + 32, as: UInt16.self) })
            let localHeaderOffset = data.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: currentCD + 42, as: UInt32.self) }
            
            let nameStart = currentCD + 46
            guard nameStart + nameLen <= data.count else { break }
            let nameData = data.subdata(in: nameStart..<(nameStart + nameLen))
            let fileName = String(data: nameData, encoding: .utf8) ?? ""
            
            entries[fileName] = ZipEntry(
                fileName: fileName,
                compressedSize: compSize,
                uncompressedSize: uncompSize,
                compressionMethod: method,
                localHeaderOffset: localHeaderOffset
            )
            
            currentCD += 46 + nameLen + extraLen + commentLen
        }
        return entries
    }
    
    func decompress(entry: ZipEntry) -> Data? {
        let loc = Int(entry.localHeaderOffset)
        guard loc + 30 <= data.count else { return nil }
        let nameLen = Int(data.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: loc + 26, as: UInt16.self) })
        let extraLen = Int(data.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: loc + 28, as: UInt16.self) })
        let dataStart = loc + 30 + nameLen + extraLen
        
        guard dataStart + entry.compressedSize <= data.count else { return nil }
        let compData = data.subdata(in: dataStart..<(dataStart + entry.compressedSize))
        
        if entry.compressionMethod == 0 {
            return compData
        } else if entry.compressionMethod == 8 {
            var strm = z_stream()
            var buffer = Data(count: entry.uncompressedSize)
            var success = false
            
            compData.withUnsafeBytes { compBytes in
                buffer.withUnsafeMutableBytes { bufBytes in
                    strm.next_in = UnsafeMutablePointer(mutating: compBytes.bindMemory(to: Bytef.self).baseAddress)
                    strm.avail_in = uInt(entry.compressedSize)
                    strm.next_out = bufBytes.bindMemory(to: Bytef.self).baseAddress
                    strm.avail_out = uInt(entry.uncompressedSize)
                    
                    guard inflateInit2_(&strm, -MAX_WBITS, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size)) == Z_OK else { return }
                    let status = inflate(&strm, Z_FINISH)
                    inflateEnd(&strm)
                    if status == Z_STREAM_END {
                        success = true
                    }
                }
            }
            return success ? buffer : nil
        }
        return nil
    }
}

// MARK: - XML Parsers

private class SharedStringsParser: NSObject, XMLParserDelegate {
    var strings: [String] = []
    private var currentText = ""
    private var isInsideT = false
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if elementName == "t" {
            isInsideT = true
        } else if elementName == "si" {
            currentText = ""
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if isInsideT {
            currentText += string
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "t" {
            isInsideT = false
        } else if elementName == "si" {
            strings.append(currentText)
        }
    }
}

private class WorkbookParser: NSObject, XMLParserDelegate {
    struct SheetInfo {
        let name: String
        let rId: String
    }
    
    var sheetInfos: [SheetInfo] = []
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if elementName == "sheet" {
            if let name = attributeDict["name"],
               let rId = attributeDict["r:id"] ?? attributeDict["id"] {
                sheetInfos.append(SheetInfo(name: name, rId: rId))
            }
        }
    }
}

private class WorkbookRelsParser: NSObject, XMLParserDelegate {
    var relMap: [String: String] = [:] // rId -> Target
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if elementName == "Relationship" {
            if let id = attributeDict["Id"], let target = attributeDict["Target"] {
                relMap[id] = target
            }
        }
    }
}

private class SheetXmlParser: NSObject, XMLParserDelegate {
    var cells: [String: XLSXCell] = [:]
    var maxRow = 0
    var maxCol = 0
    
    private let sharedStrings: [String]
    
    private var currentRef: String?
    private var currentType: String?
    private var currentVal: String?
    private var currentFormula: String?
    private var isInsideV = false
    private var isInsideF = false
    
    init(sharedStrings: [String]) {
        self.sharedStrings = sharedStrings
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if elementName == "c" {
            currentRef = attributeDict["r"]
            currentType = attributeDict["t"]
            currentVal = nil
            currentFormula = nil
        } else if elementName == "v" {
            isInsideV = true
            currentVal = ""
        } else if elementName == "f" {
            isInsideF = true
            currentFormula = ""
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if isInsideV {
            currentVal = (currentVal ?? "") + string
        } else if isInsideF {
            currentFormula = (currentFormula ?? "") + string
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "v" {
            isInsideV = false
        } else if elementName == "f" {
            isInsideF = false
        } else if elementName == "c" {
            if let ref = currentRef {
                if let (col, row) = XLSXSheet.columnAndRow(from: ref) {
                    maxRow = max(maxRow, row)
                    maxCol = max(maxCol, col)
                    
                    let isSS = (currentType == "s")
                    var finalVal: String? = currentVal
                    if isSS, let valStr = currentVal, let idx = Int(valStr), idx >= 0 && idx < sharedStrings.count {
                        finalVal = sharedStrings[idx]
                    }
                    
                    cells[ref.uppercased()] = XLSXCell(
                        reference: ref.uppercased(),
                        rowIndex: row,
                        columnIndex: col,
                        value: finalVal,
                        rawValue: currentVal,
                        formula: currentFormula,
                        isSharedString: isSS
                    )
                }
            }
            currentRef = nil
            currentType = nil
            currentVal = nil
            currentFormula = nil
        }
    }
}

// MARK: - XLSX Parser Public Interface

public class XLSXParser {
    public static let shared = XLSXParser()
    
    private init() {}
    
    public func parseWorkbook(from url: URL) throws -> XLSXWorkbook {
        let fileData: Data
        do {
            fileData = try Data(contentsOf: url)
        } catch {
            throw CSVParserError.fileReadFailed
        }
        
        let zip = SimpleZipUnpacker(data: fileData)
        let entries = zip.readEntries()
        
        guard !entries.isEmpty else {
            throw CSVParserError.invalidFormat
        }
        
        // 1. Parse Shared Strings
        var sharedStrings: [String] = []
        if let ssEntry = entries["xl/sharedStrings.xml"], let ssData = zip.decompress(entry: ssEntry) {
            let ssDelegate = SharedStringsParser()
            let parser = XMLParser(data: ssData)
            parser.delegate = ssDelegate
            parser.parse()
            sharedStrings = ssDelegate.strings
        }
        
        // 2. Parse Workbook XML
        guard let wbEntry = entries["xl/workbook.xml"], let wbData = zip.decompress(entry: wbEntry) else {
            throw CSVParserError.invalidFormat
        }
        let wbDelegate = WorkbookParser()
        let wbParser = XMLParser(data: wbData)
        wbParser.delegate = wbDelegate
        wbParser.parse()
        
        // 3. Parse Relationships XML
        var relMap: [String: String] = [:]
        if let relsEntry = entries["xl/_rels/workbook.xml.rels"], let relsData = zip.decompress(entry: relsEntry) {
            let relsDelegate = WorkbookRelsParser()
            let relsParser = XMLParser(data: relsData)
            relsParser.delegate = relsDelegate
            relsParser.parse()
            relMap = relsDelegate.relMap
        }
        
        // 4. Parse Sheets
        var parsedSheets: [XLSXSheet] = []
        for info in wbDelegate.sheetInfos {
            guard let target = relMap[info.rId] else { continue }
            let sheetPath = target.hasPrefix("xl/") ? target : "xl/" + target
            
            guard let sheetEntry = entries[sheetPath], let sheetData = zip.decompress(entry: sheetEntry) else {
                continue
            }
            
            let sheetDelegate = SheetXmlParser(sharedStrings: sharedStrings)
            let parser = XMLParser(data: sheetData)
            parser.delegate = sheetDelegate
            parser.parse()
            
            let sheet = XLSXSheet(
                name: info.name,
                targetPath: sheetPath,
                cells: sheetDelegate.cells,
                maxRow: sheetDelegate.maxRow,
                maxColumn: sheetDelegate.maxCol
            )
            parsedSheets.append(sheet)
        }
        
        return XLSXWorkbook(sheets: parsedSheets)
    }
}
