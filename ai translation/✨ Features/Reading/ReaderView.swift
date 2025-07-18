// ReaderView.swift - 完整EPUB WebKit閱讀器

import SwiftUI
import WebKit
import ZIPFoundation
import Foundation

struct ReaderView: View {
    let book: ReaderBook
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingMenu = false
    @State private var showingSettings = false
    @State private var selectedText: String = ""
    @State private var showingTextMenu = false
    @State private var textMenuPosition: CGPoint = .zero
    @State private var settings = ReaderSettings()
    @State private var epubReader = EPUBReader()
    @State private var isLoading = true
    @State private var loadingError: String?
    @State private var currentChapterIndex = 0
    @State private var chapterTitles: [String] = []
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 頂部工具列
                if showingMenu {
                    ReaderTopToolbar(
                        bookTitle: book.title,
                        onClose: { dismiss() },
                        onSettings: { showingSettings = true }
                    )
                    .transition(.move(edge: .top))
                }
                
                // 主要閱讀區域
                ZStack {
                    if isLoading {
                        LoadingView(message: "正在載入EPUB...")
                    } else if let error = loadingError {
                        ErrorView(message: error) {
                            Task { await loadEPUB() }
                        }
                    } else {
                        if book.isEPUB {
                            EPUBWebView(
                                reader: epubReader,
                                chapterIndex: $currentChapterIndex,
                                settings: settings
                            )
                        } else {
                            // 非EPUB檔案的傳統閱讀器
                            TraditionalReaderView(
                                book: book,
                                settings: settings,
                                selectedText: $selectedText,
                                showingTextMenu: $showingTextMenu,
                                textMenuPosition: $textMenuPosition
                            )
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // 底部工具列
                if showingMenu && !isLoading && loadingError == nil {
                    if book.isEPUB {
                        EPUBBottomToolbar(
                            currentChapter: currentChapterIndex + 1,
                            totalChapters: chapterTitles.count,
                            chapterTitles: chapterTitles,
                            onChapterChange: { index in
                                currentChapterIndex = index
                                Task { await epubReader.loadChapter(at: index) }
                            }
                        )
                        .transition(.move(edge: .bottom))
                    } else {
                        TraditionalBottomToolbar(
                            currentPage: book.currentPage,
                            totalPages: book.totalPages,
                            progress: Double(book.currentPage) / Double(book.totalPages),
                            onPageChange: { page in
                                // 這裡可以實作頁面切換
                            }
                        )
                        .transition(.move(edge: .bottom))
                    }
                }
            }
            
            // 文字選擇功能表
            if showingTextMenu {
                TextSelectionMenu(
                    selectedText: selectedText,
                    position: textMenuPosition,
                    onHighlight: {
                        // 實作螢光筆功能
                        showingTextMenu = false
                    },
                    onAddNote: {
                        // 實作筆記功能
                        showingTextMenu = false
                    },
                    onCreateKnowledgePoint: {
                        // 實作知識點功能
                        showingTextMenu = false
                    },
                    onDismiss: {
                        showingTextMenu = false
                        selectedText = ""
                    }
                )
            }
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.3)) {
                showingMenu.toggle()
            }
        }
        .sheet(isPresented: $showingSettings) {
            ReaderSettingsView(settings: $settings)
        }
        .task {
            if book.isEPUB {
                await loadEPUB()
            } else {
                // 非EPUB檔案直接顯示
                isLoading = false
            }
        }
    }
    
    private func loadEPUB() async {
        isLoading = true
        loadingError = nil
        
        do {
            // 取得EPUB檔案路徑
            guard let epubPath = getEPUBFilePath() else {
                throw EPUBError.fileNotFound
            }
            
            // 載入EPUB
            try await epubReader.loadEPUB(from: epubPath)
            
            // 取得章節標題
            chapterTitles = epubReader.getChapterTitles()
            currentChapterIndex = book.currentChapterIndex
            
            // 載入第一章並應用當前設定
            if !chapterTitles.isEmpty {
                await epubReader.loadChapter(at: currentChapterIndex, with: settings)
            }
            
            await MainActor.run {
                isLoading = false
            }
            
        } catch {
            await MainActor.run {
                isLoading = false
                loadingError = "載入EPUB失敗：\(error.localizedDescription)"
            }
        }
    }
    
    private func getEPUBFilePath() -> String? {
        // 從Books目錄找到對應的EPUB檔案
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let bookDirectory = documentsPath.appendingPathComponent("Books").appendingPathComponent(book.id.uuidString)
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: bookDirectory, includingPropertiesForKeys: nil)
            
            for file in files {
                if file.pathExtension.lowercased() == "epub" {
                    return file.path
                }
            }
        } catch {
            print("❌ 無法讀取書籍目錄：\(error)")
        }
        
        return nil
    }
}

// MARK: - EPUB閱讀器核心

@MainActor
class EPUBReader: ObservableObject {
    private var epubDirectory: URL?
    private var chapters: [EPUBChapterInfo] = []
    private var currentSettings: ReaderSettings = ReaderSettings()
    
    @Published var webViewHTML: String = ""
    @Published var isReady = false
    
    func loadEPUB(from path: String) async throws {
        let epubURL = URL(fileURLWithPath: path)
        
        // 創建臨時解壓縮目錄
        let tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        
        // 解壓縮EPUB - 使用正確的ZIPFoundation API
        guard let archive = Archive(url: epubURL, accessMode: .read) else {
            throw EPUBError.extractionFailed
        }
        
        for entry in archive {
            let destinationURL = tempDirectory.appendingPathComponent(entry.path)
            
            // 確保目標目錄存在
            let destinationDirectory = destinationURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: destinationDirectory, withIntermediateDirectories: true)
            
            // 解壓縮單個檔案
            _ = try archive.extract(entry, to: destinationURL)
        }
        
        epubDirectory = tempDirectory
        
        // 解析EPUB結構
        try await parseEPUBStructure()
        
        // 載入第一章
        if !chapters.isEmpty {
            await loadChapter(at: 0, with: currentSettings)
        }
        
        isReady = true
    }
    
    private func parseEPUBStructure() async throws {
        guard let epubDir = epubDirectory else { throw EPUBError.invalidStructure }
        
        print("📁 EPUB解壓縮目錄: \(epubDir.path)")
        
        // 列出解壓縮後的所有檔案
        do {
            let allFiles = try FileManager.default.contentsOfDirectory(at: epubDir, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
            print("📋 解壓縮後的檔案:")
            for file in allFiles {
                print("  - \(file.lastPathComponent)")
            }
        } catch {
            print("❌ 無法列出解壓縮檔案: \(error)")
        }
        
        // 1. 讀取META-INF/container.xml
        let containerPath = epubDir.appendingPathComponent("META-INF/container.xml")
        print("🔍 尋找container.xml: \(containerPath.path)")
        
        guard FileManager.default.fileExists(atPath: containerPath.path) else {
            print("❌ container.xml 不存在")
            throw EPUBError.invalidStructure
        }
        
        let containerData = try Data(contentsOf: containerPath)
        let containerXML = String(data: containerData, encoding: .utf8) ?? ""
        print("📄 Container.xml內容: \(containerXML)")
        
        // 2. 提取OPF檔案路徑
        guard let opfPath = extractOPFPath(from: containerXML) else {
            print("❌ 無法從container.xml找到OPF路徑")
            throw EPUBError.invalidStructure
        }
        
        print("📍 找到OPF路徑: \(opfPath)")
        
        // 3. 讀取OPF檔案
        let opfFullPath = epubDir.appendingPathComponent(opfPath)
        print("🔍 讀取OPF檔案: \(opfFullPath.path)")
        
        guard FileManager.default.fileExists(atPath: opfFullPath.path) else {
            print("❌ OPF檔案不存在: \(opfFullPath.path)")
            throw EPUBError.invalidStructure
        }
        
        let opfData = try Data(contentsOf: opfFullPath)
        let opfXML = String(data: opfData, encoding: .utf8) ?? ""
        print("📄 OPF檔案大小: \(opfData.count) bytes")
        
        // 4. 解析章節資訊
        chapters = try parseChaptersFromOPF(opfXML, basePath: opfPath)
        
        print("✅ 成功解析EPUB，找到 \(chapters.count) 個章節")
    }
    
    private func extractOPFPath(from containerXML: String) -> String? {
        // 簡單的XML解析來找到OPF檔案路徑
        let pattern = #"full-path="([^"]*\.opf)""#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: containerXML, range: NSRange(containerXML.startIndex..., in: containerXML)) {
            if let range = Range(match.range(at: 1), in: containerXML) {
                return String(containerXML[range])
            }
        }
        return nil
    }
    
    private func parseChaptersFromOPF(_ opfXML: String, basePath: String) throws -> [EPUBChapterInfo] {
        var chapterList: [EPUBChapterInfo] = []
        
        print("🔍 開始解析OPF檔案...")
        print("📄 OPF內容片段: \(String(opfXML.prefix(200)))")
        
        // 更寬鬆的spine解析模式
        let spinePatterns = [
            "<itemref[^>]*idref=\"([^\"]*?)\"[^>]*?/?>",
            "<itemref[^>]*idref='([^']*?)'[^>]*?/?>",
            "idref=\"([^\"]*?)\"",
            "idref='([^']*?)'"
        ]
        
        var spineIds: [String] = []
        for pattern in spinePatterns {
            if let spineRegex = try? NSRegularExpression(pattern: pattern) {
                let matches = spineRegex.matches(in: opfXML, range: NSRange(opfXML.startIndex..., in: opfXML))
                for match in matches {
                    if let range = Range(match.range(at: 1), in: opfXML) {
                        let id = String(opfXML[range])
                        if !spineIds.contains(id) {
                            spineIds.append(id)
                        }
                    }
                }
                if !spineIds.isEmpty {
                    break // 找到匹配就停止
                }
            }
        }
        
        print("📋 找到的spine IDs: \(spineIds)")
        
        // 更強化的manifest解析 - 去掉media-type限制
        let manifestPatterns = [
            // 不限制media-type，所有item都解析
            "<item[^>]*id=\"([^\"]*?)\"[^>]*href=\"([^\"]*?)\"[^>]*?/?>",
            "<item[^>]*id='([^']*?)'[^>]*href='([^']*?)'[^>]*?/?>",
            // 更寬鬆的模式，不要求順序
            "id=\"([^\"]*?)\"[^>]*href=\"([^\"]*?)\"",
            "href=\"([^\"]*?)\"[^>]*id=\"([^\"]*?)\"",
            "id='([^']*?)'[^>]*href='([^']*?)'",
            "href='([^']*?)'[^>]*id='([^']*?)'"
        ]
        
        var idToHref: [String: String] = [:]
        for (patternIndex, pattern) in manifestPatterns.enumerated() {
            if let manifestRegex = try? NSRegularExpression(pattern: pattern) {
                let matches = manifestRegex.matches(in: opfXML, range: NSRange(opfXML.startIndex..., in: opfXML))
                print("🔍 使用pattern \(patternIndex): 找到 \(matches.count) 個匹配")
                
                for match in matches {
                    var id: String?
                    var href: String?
                    
                    // 根據不同pattern調整提取順序
                    if patternIndex < 2 {
                        // 標準順序: id, href
                        if let idRange = Range(match.range(at: 1), in: opfXML),
                           let hrefRange = Range(match.range(at: 2), in: opfXML) {
                            id = String(opfXML[idRange])
                            href = String(opfXML[hrefRange])
                        }
                    } else if patternIndex == 2 {
                        // id在前: id, href
                        if let idRange = Range(match.range(at: 1), in: opfXML),
                           let hrefRange = Range(match.range(at: 2), in: opfXML) {
                            id = String(opfXML[idRange])
                            href = String(opfXML[hrefRange])
                        }
                    } else if patternIndex == 3 {
                        // href在前: href, id
                        if let hrefRange = Range(match.range(at: 1), in: opfXML),
                           let idRange = Range(match.range(at: 2), in: opfXML) {
                            href = String(opfXML[hrefRange])
                            id = String(opfXML[idRange])
                        }
                    } else if patternIndex == 4 {
                        // 單引號 id在前
                        if let idRange = Range(match.range(at: 1), in: opfXML),
                           let hrefRange = Range(match.range(at: 2), in: opfXML) {
                            id = String(opfXML[idRange])
                            href = String(opfXML[hrefRange])
                        }
                    } else if patternIndex == 5 {
                        // 單引號 href在前
                        if let hrefRange = Range(match.range(at: 1), in: opfXML),
                           let idRange = Range(match.range(at: 2), in: opfXML) {
                            href = String(opfXML[hrefRange])
                            id = String(opfXML[idRange])
                        }
                    }
                    
                    if let id = id, let href = href {
                        // 過濾掉非HTML檔案，但條件更寬鬆
                        let lowerHref = href.lowercased()
                        if lowerHref.hasSuffix(".html") || lowerHref.hasSuffix(".xhtml") || lowerHref.hasSuffix(".htm") || lowerHref.contains("html") {
                            idToHref[id] = href
                            print("  ✅ 映射: \(id) -> \(href)")
                        } else {
                            print("  ⚠️ 跳過非HTML: \(id) -> \(href)")
                        }
                    }
                }
                if !idToHref.isEmpty {
                    break // 找到匹配就停止
                }
            }
        }
        
        print("📁 找到的檔案映射: \(idToHref)")
        
        // 如果還是沒有找到映射，嘗試手動查找OEBPS目錄下的HTML檔案
        if idToHref.isEmpty {
            print("⚠️ manifest解析失敗，嘗試直接掃描HTML檔案")
            if let epubDir = epubDirectory {
                let oebpsDir = epubDir.appendingPathComponent("OEBPS")
                do {
                    let files = try FileManager.default.contentsOfDirectory(at: oebpsDir, includingPropertiesForKeys: nil)
                    for file in files {
                        let fileName = file.lastPathComponent
                        let lowerName = fileName.lowercased()
                        if lowerName.hasSuffix(".html") || lowerName.hasSuffix(".xhtml") || lowerName.hasSuffix(".htm") {
                            // 嘗試從檔案名猜測ID
                            let fileNameWithoutExt = file.deletingPathExtension().lastPathComponent
                            idToHref[fileNameWithoutExt] = fileName
                            print("  📄 直接掃描找到: \(fileNameWithoutExt) -> \(fileName)")
                        }
                    }
                } catch {
                    print("❌ 無法掃描OEBPS目錄: \(error)")
                }
            }
        }
        
        // 如果沒有找到spine，嘗試直接使用所有HTML檔案
        if spineIds.isEmpty && !idToHref.isEmpty {
            print("⚠️ 未找到spine，使用所有HTML檔案")
            spineIds = Array(idToHref.keys).sorted()
        }
        
        // 根據spine順序建立章節列表
        let baseDir = URL(fileURLWithPath: basePath).deletingLastPathComponent().path
        
        for (index, id) in spineIds.enumerated() {
            if let href = idToHref[id] {
                let fullHref = baseDir.isEmpty ? href : "\(baseDir)/\(href)"
                
                // 嘗試從檔案名稱提取標題
                let fileName = URL(fileURLWithPath: href).lastPathComponent
                var chapterTitle = "Chapter \(index + 1)"
                
                // 如果檔案名包含有意義的資訊，使用它
                if fileName != href {
                    chapterTitle = fileName.replacingOccurrences(of: ".html", with: "")
                        .replacingOccurrences(of: ".xhtml", with: "")
                        .replacingOccurrences(of: "_", with: " ")
                        .capitalized
                }
                
                let chapter = EPUBChapterInfo(
                    title: chapterTitle,
                    htmlFileName: fileName,
                    order: index,
                    href: fullHref
                )
                chapterList.append(chapter)
            } else {
                print("⚠️ 找不到ID對應的檔案: \(id)")
            }
        }
        
        print("✅ 成功建立 \(chapterList.count) 個章節")
        for (index, chapter) in chapterList.enumerated() {
            print("📖 第\(index+1)章: \(chapter.title) -> \(chapter.href)")
        }
        
        return chapterList
    }
    
    func loadChapter(at index: Int, with settings: ReaderSettings = ReaderSettings()) async {
        guard index < chapters.count, let epubDir = epubDirectory else {
            print("❌ 載入章節失敗：index=\(index), chapters.count=\(chapters.count)")
            return
        }
        
        // 儲存當前設定
        currentSettings = settings
        
        let chapter = chapters[index]
        let chapterPath = epubDir.appendingPathComponent(chapter.href)
        
        print("📖 嘗試載入章節 \(index): \(chapter.title)")
        print("📁 章節檔案路徑: \(chapterPath.path)")
        print("📄 檔案是否存在: \(FileManager.default.fileExists(atPath: chapterPath.path))")
        print("⚙️ 應用設定 - 字體大小: \(settings.fontSize), 行距: \(settings.lineSpacing), 邊距: \(settings.pageMargin)")
        
        do {
            let htmlData = try Data(contentsOf: chapterPath)
            var htmlContent = String(data: htmlData, encoding: .utf8) ?? ""
            
            print("📊 HTML檔案大小: \(htmlData.count) bytes")
            print("📝 HTML內容開頭: \(String(htmlContent.prefix(200)))")
            
            // 處理相對路徑的資源（圖片、CSS等）
            htmlContent = processRelativeLinks(htmlContent, basePath: chapterPath.deletingLastPathComponent())
            
            // 應用閱讀設定的CSS
            htmlContent = applyReaderStyles(to: htmlContent, with: settings)
            
            print("✅ HTML處理完成，內容長度: \(htmlContent.count)")
            print("🎨 CSS設定已應用")
            
            await MainActor.run {
                self.webViewHTML = htmlContent
                print("🌐 WebView HTML已更新")
            }
            
        } catch {
            print("❌ 載入章節失敗：\(error)")
            print("📁 嘗試列出目錄內容...")
            
            // 列出目錄內容進行調試
            let parentDir = chapterPath.deletingLastPathComponent()
            do {
                let files = try FileManager.default.contentsOfDirectory(at: parentDir, includingPropertiesForKeys: nil)
                print("📋 目錄 \(parentDir.lastPathComponent) 內容:")
                for file in files.prefix(10) { // 只顯示前10個檔案
                    print("  - \(file.lastPathComponent)")
                }
                if files.count > 10 {
                    print("  ... 還有 \(files.count - 10) 個檔案")
                }
            } catch {
                print("❌ 無法列出目錄內容: \(error)")
            }
        }
    }
    
    private func processRelativeLinks(_ html: String, basePath: URL) -> String {
        // 將相對路徑轉換為file://協議的絕對路徑
        var processedHTML = html
        
        // 處理圖片src
        let imgPattern = #"src="([^"]*\.(?:jpg|jpeg|png|gif|svg))""#
        if let imgRegex = try? NSRegularExpression(pattern: imgPattern) {
            processedHTML = imgRegex.stringByReplacingMatches(
                in: processedHTML,
                range: NSRange(processedHTML.startIndex..., in: processedHTML),
                withTemplate: "src=\"file://\(basePath.path)/$1\""
            )
        }
        
        // 處理CSS link
        let cssPattern = #"href="([^"]*\.css)""#
        if let cssRegex = try? NSRegularExpression(pattern: cssPattern) {
            processedHTML = cssRegex.stringByReplacingMatches(
                in: processedHTML,
                range: NSRange(processedHTML.startIndex..., in: processedHTML),
                withTemplate: "href=\"file://\(basePath.path)/$1\""
            )
        }
        
        return processedHTML
    }
    
    private func applyReaderStyles(to html: String, with settings: ReaderSettings) -> String {
        // 根據背景色決定文字顏色
        let textColor = getTextColorForBackground(settings.backgroundColor)
        let bgColor = colorToCSS(settings.backgroundColor.color)
        
        let readerCSS = """
        <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', 'PingFang TC', 'Helvetica Neue', Arial, sans-serif;
            font-size: \(settings.fontSize)px;
            line-height: \(settings.lineSpacing);
            margin: 0;
            padding: \(settings.pageMargin)px;
            color: \(textColor);
            background-color: \(bgColor);
            max-width: 100%;
            overflow-x: hidden;
            text-align: justify;
            word-wrap: break-word;
        }
        p {
            margin-bottom: 1.2em;
            text-align: justify;
            text-justify: inter-word;
        }
        h1, h2, h3, h4, h5, h6 {
            color: \(textColor);
            margin-top: 2em;
            margin-bottom: 1em;
            font-weight: 600;
            line-height: 1.4;
        }
        h1 {
            font-size: \(settings.fontSize + 6)px;
            text-align: center;
            margin-bottom: 1.5em;
        }
        h2 {
            font-size: \(settings.fontSize + 4)px;
        }
        h3 {
            font-size: \(settings.fontSize + 2)px;
        }
        img {
            max-width: 100%;
            height: auto;
            display: block;
            margin: 1.5em auto;
            border-radius: 8px;
        }
        blockquote {
            margin: 1.5em 0;
            padding: 1em 1.5em;
            border-left: 4px solid #3498db;
            background-color: rgba(52, 152, 219, 0.1);
            font-style: italic;
        }
        a {
            color: #3498db;
            text-decoration: none;
        }
        a:hover {
            text-decoration: underline;
        }
        ul, ol {
            margin: 1em 0;
            padding-left: 2em;
        }
        li {
            margin-bottom: 0.5em;
            line-height: \(settings.lineSpacing);
        }
        /* 段落首行縮排 */
        p + p {
            text-indent: 2em;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 1.5em 0;
        }
        th, td {
            padding: 0.8em;
            border: 1px solid rgba(128, 128, 128, 0.3);
            text-align: left;
        }
        th {
            background-color: rgba(128, 128, 128, 0.1);
            font-weight: 600;
        }
        </style>
        """
        
        // 將CSS插入到head中
        if html.contains("</head>") {
            return html.replacingOccurrences(of: "</head>", with: "\(readerCSS)</head>")
        } else {
            return "\(readerCSS)\(html)"
        }
    }
    
    private func getTextColorForBackground(_ bgColor: ReaderSettings.ReaderBackgroundColor) -> String {
        switch bgColor {
        case .white:
            return "#2c3e50"  // 深色文字
        case .sepia:
            return "#5d4037"  // 深棕色文字
        case .dark:
            return "#e8e8e8"  // 淺色文字
        }
    }
    
    private func colorToCSS(_ color: Color) -> String {
        // 將SwiftUI Color轉換為CSS顏色
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return "rgba(\(Int(red * 255)), \(Int(green * 255)), \(Int(blue * 255)), \(alpha))"
    }
    
    func getChapterTitles() -> [String] {
        return chapters.map { $0.title }
    }
    
    func getCurrentChapterCount() -> Int {
        return chapters.count
    }
    
    deinit {
        // 清理臨時檔案
        if let epubDir = epubDirectory {
            try? FileManager.default.removeItem(at: epubDir)
        }
    }
}

// MARK: - WebKit整合

struct EPUBWebView: UIViewRepresentable {
    let reader: EPUBReader
    @Binding var chapterIndex: Int
    let settings: ReaderSettings
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.suppressesIncrementalRendering = false
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.backgroundColor = UIColor.systemBackground
        webView.isOpaque = false
        webView.scrollView.backgroundColor = UIColor.systemBackground
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        if !reader.webViewHTML.isEmpty {
            print("🌐 WebView 開始載入 HTML，長度: \(reader.webViewHTML.count)")
            print("📱 WebView frame: \(webView.frame)")
            print("🔗 HTML 開頭: \(String(reader.webViewHTML.prefix(200)))")
            
            webView.loadHTMLString(reader.webViewHTML, baseURL: nil)
        } else {
            print("⚠️ WebView HTML 為空")
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: EPUBWebView
        
        init(_ parent: EPUBWebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("✅ WebView 章節載入完成")
            
            // 檢查WebView內容
            webView.evaluateJavaScript("document.body.innerHTML.length") { result, error in
                if let length = result as? Int {
                    print("📄 WebView 內容長度: \(length)")
                } else {
                    print("❌ 無法獲取WebView內容長度: \(String(describing: error))")
                }
            }
            
            webView.evaluateJavaScript("document.title") { result, error in
                if let title = result as? String {
                    print("📖 頁面標題: \(title)")
                }
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("❌ WebView載入失敗：\(error)")
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("❌ WebView初步載入失敗：\(error)")
        }
    }
}

// MARK: - 傳統閱讀器（用於非EPUB檔案）

struct TraditionalReaderView: View {
    let book: ReaderBook
    let settings: ReaderSettings
    @Binding var selectedText: String
    @Binding var showingTextMenu: Bool
    @Binding var textMenuPosition: CGPoint
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(book.getPageContent(page: book.currentPage))
                    .font(.system(size: settings.fontSize))
                    .lineSpacing(settings.lineSpacing * 4)
                    .foregroundStyle(.primary)
                    .textSelection(.enabled)
                    .padding(.horizontal, settings.pageMargin)
                    .padding(.vertical, 20)
                    .background(settings.backgroundColor.color)
            }
        }
        .background(settings.backgroundColor.color)
    }
}

// MARK: - UI組件

struct LoadingView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.orange)
            
            Text(message)
                .font(.appCallout())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundStyle(.orange)
            
            Text("載入失敗")
                .font(.appTitle2())
                .fontWeight(.bold)
            
            Text(message)
                .font(.appCallout())
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button("重新載入", action: onRetry)
                .font(.appCallout())
                .foregroundStyle(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .background(.orange, in: RoundedRectangle(cornerRadius: 8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct EPUBBottomToolbar: View {
    let currentChapter: Int
    let totalChapters: Int
    let chapterTitles: [String]
    let onChapterChange: (Int) -> Void
    
    @State private var showingChapterList = false
    
    var body: some View {
        VStack(spacing: 12) {
            // 章節進度條
            HStack {
                Button(action: {
                    if currentChapter > 1 {
                        onChapterChange(currentChapter - 2)
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.appTitle3())
                        .foregroundStyle(currentChapter > 1 ? .primary : .secondary)
                }
                .disabled(currentChapter <= 1)
                
                Spacer()
                
                Button(action: { showingChapterList = true }) {
                    VStack(spacing: 2) {
                        Text("第 \(currentChapter) 章 / 共 \(totalChapters) 章")
                            .font(.appSubheadline())
                            .foregroundStyle(.primary)
                        
                        if currentChapter <= chapterTitles.count {
                            Text(chapterTitles[currentChapter - 1])
                                .font(.appCaption())
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                
                Spacer()
                
                Button(action: {
                    if currentChapter < totalChapters {
                        onChapterChange(currentChapter)
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.appTitle3())
                        .foregroundStyle(currentChapter < totalChapters ? .primary : .secondary)
                }
                .disabled(currentChapter >= totalChapters)
            }
            
            // 操作按鈕
            HStack(spacing: 40) {
                Button(action: {}) {
                    Image(systemName: "bookmark")
                        .font(.appTitle3())
                        .foregroundStyle(.primary)
                }
                
                Button(action: {}) {
                    Image(systemName: "note.text")
                        .font(.appTitle3())
                        .foregroundStyle(.primary)
                }
                
                Button(action: {}) {
                    Image(systemName: "magnifyingglass")
                        .font(.appTitle3())
                        .foregroundStyle(.primary)
                }
                
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.appTitle3())
                        .foregroundStyle(.primary)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .sheet(isPresented: $showingChapterList) {
            ChapterListView(
                chapters: chapterTitles,
                currentChapter: currentChapter - 1,
                onChapterSelect: { index in
                    onChapterChange(index)
                    showingChapterList = false
                }
            )
        }
    }
}

struct TraditionalBottomToolbar: View {
    let currentPage: Int
    let totalPages: Int
    let progress: Double
    let onPageChange: (Int) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // 進度條
            HStack {
                Text("\(currentPage)")
                    .font(.appSubheadline())
                    .foregroundStyle(.secondary)
                    .frame(width: 30)
                
                Slider(
                    value: Binding(
                        get: { Double(currentPage) },
                        set: { onPageChange(Int($0)) }
                    ),
                    in: 1...Double(totalPages),
                    step: 1
                )
                .tint(.orange)
                
                Text("\(totalPages)")
                    .font(.appSubheadline())
                    .foregroundStyle(.secondary)
                    .frame(width: 30)
            }
            
            // 操作按鈕
            HStack(spacing: 40) {
                Button(action: {}) {
                    Image(systemName: "bookmark")
                        .font(.appTitle3())
                        .foregroundStyle(.primary)
                }
                
                Button(action: {}) {
                    Image(systemName: "note.text")
                        .font(.appTitle3())
                        .foregroundStyle(.primary)
                }
                
                Button(action: {}) {
                    Image(systemName: "magnifyingglass")
                        .font(.appTitle3())
                        .foregroundStyle(.primary)
                }
                
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.appTitle3())
                        .foregroundStyle(.primary)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
}

struct ChapterListView: View {
    let chapters: [String]
    let currentChapter: Int
    let onChapterSelect: (Int) -> Void
    
    var body: some View {
        NavigationView {
            List {
                ForEach(chapters.indices, id: \.self) { index in
                    Button(action: { onChapterSelect(index) }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("第 \(index + 1) 章")
                                    .font(.appCallout())
                                    .fontWeight(.medium)
                                    .foregroundStyle(.primary)
                                
                                Text(chapters[index])
                                    .font(.appSubheadline())
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                            
                            if index == currentChapter {
                                Image(systemName: "play.circle.fill")
                                    .foregroundStyle(.orange)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("章節目錄")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ReaderTopToolbar: View {
    let bookTitle: String
    let onClose: () -> Void
    let onSettings: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.appHeadline())
                    .foregroundStyle(.primary)
            }
            
            Spacer()
            
            Text(bookTitle)
                .font(.appCallout())
                .foregroundStyle(.primary)
                .lineLimit(1)
            
            Spacer()
            
            Button(action: onSettings) {
                Image(systemName: "textformat.size")
                    .font(.appHeadline())
                    .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
}

struct TextSelectionMenu: View {
    let selectedText: String
    let position: CGPoint
    let onHighlight: () -> Void
    let onAddNote: () -> Void
    let onCreateKnowledgePoint: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 選中的文字預覽
            Text("\"" + (selectedText.count > 50 ? String(selectedText.prefix(50)) + "..." : selectedText) + "\"")
                .font(.appSubheadline())
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, 16)
                .padding(.top, 12)
            
            Divider()
            
            // 操作按鈕
            VStack(spacing: 8) {
                Button(action: onHighlight) {
                    HStack {
                        Image(systemName: "highlighter")
                            .frame(width: 20)
                        Text("螢光筆")
                        Spacer()
                    }
                    .font(.appCallout())
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                
                Button(action: onAddNote) {
                    HStack {
                        Image(systemName: "note.text")
                            .frame(width: 20)
                        Text("新增筆記")
                        Spacer()
                    }
                    .font(.appCallout())
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                
                Button(action: onCreateKnowledgePoint) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .frame(width: 20)
                        Text("建立知識點")
                        Spacer()
                    }
                    .font(.appCallout())
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .padding(.bottom, 8)
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
        .position(x: position.x, y: max(120, position.y - 50))
        .onTapGesture {
            // 防止點擊菜單時關閉
        }
        .background(
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    onDismiss()
                }
        )
    }
}

// MARK: - 錯誤類型

enum EPUBError: LocalizedError {
    case fileNotFound
    case invalidStructure
    case extractionFailed
    case parsingFailed
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "找不到EPUB檔案"
        case .invalidStructure:
            return "EPUB檔案結構無效"
        case .extractionFailed:
            return "解壓縮EPUB檔案失敗"
        case .parsingFailed:
            return "解析EPUB內容失敗"
        }
    }
}

// MARK: - 字體擴展

extension Font {
    static func appTitle2() -> Font {
        return .system(size: 22, weight: .bold, design: .default)
    }
    
    static func appTitle3() -> Font {
        return .system(size: 20, weight: .semibold, design: .default)
    }
    
    static func appHeadline() -> Font {
        return .system(size: 17, weight: .semibold, design: .default)
    }
    
    static func appCallout() -> Font {
        return .system(size: 16, weight: .regular, design: .default)
    }
    
    static func appSubheadline() -> Font {
        return .system(size: 15, weight: .regular, design: .default)
    }
    
    static func appCaption() -> Font {
        return .system(size: 12, weight: .regular, design: .default)
    }
}

#Preview {
    ReaderView(book: ReaderBook(
        title: "測試EPUB書籍",
        author: "測試作者",
        totalPages: 1,
        fileType: "epub"
    ))
}
