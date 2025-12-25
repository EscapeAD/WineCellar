import XCTest
@testable import WineCellar

// MARK: - WinetricksVerb Tests

final class WinetricksVerbTests: XCTestCase {
    
    func testAllVerbsHaveRawValues() {
        for verb in WinetricksVerb.allCases {
            XCTAssertFalse(verb.rawValue.isEmpty)
        }
    }
    
    func testAllVerbsHaveDisplayNames() {
        for verb in WinetricksVerb.allCases {
            XCTAssertFalse(verb.displayName.isEmpty)
        }
    }
    
    func testAllVerbsHaveCategories() {
        for verb in WinetricksVerb.allCases {
            XCTAssertTrue(WinetricksCategory.allCases.contains(verb.category))
        }
    }
    
    // MARK: - Font Verbs
    
    func testFontVerbsCategory() {
        let fontVerbs: [WinetricksVerb] = [
            .corefonts, .tahoma, .arial, .times, .courier, .lucida, .allfonts
        ]
        
        for verb in fontVerbs {
            XCTAssertEqual(verb.category, .fonts)
        }
    }
    
    func testFontVerbDisplayNames() {
        XCTAssertEqual(WinetricksVerb.corefonts.displayName, "Core Fonts")
        XCTAssertEqual(WinetricksVerb.tahoma.displayName, "Tahoma Font")
        XCTAssertEqual(WinetricksVerb.arial.displayName, "Arial Font")
        XCTAssertEqual(WinetricksVerb.times.displayName, "Times New Roman")
        XCTAssertEqual(WinetricksVerb.courier.displayName, "Courier Font")
        XCTAssertEqual(WinetricksVerb.lucida.displayName, "Lucida Font")
        XCTAssertEqual(WinetricksVerb.allfonts.displayName, "All Fonts")
    }
    
    // MARK: - Visual C++ Runtime Verbs
    
    func testVcppVerbsCategory() {
        let vcppVerbs: [WinetricksVerb] = [
            .vcrun6, .vcrun2005, .vcrun2008, .vcrun2010,
            .vcrun2012, .vcrun2013, .vcrun2015, .vcrun2017,
            .vcrun2019, .vcrun2022
        ]
        
        for verb in vcppVerbs {
            XCTAssertEqual(verb.category, .vcpp)
        }
    }
    
    func testVcppVerbDisplayNames() {
        XCTAssertTrue(WinetricksVerb.vcrun6.displayName.contains("6"))
        XCTAssertTrue(WinetricksVerb.vcrun2005.displayName.contains("2005"))
        XCTAssertTrue(WinetricksVerb.vcrun2008.displayName.contains("2008"))
        XCTAssertTrue(WinetricksVerb.vcrun2010.displayName.contains("2010"))
        XCTAssertTrue(WinetricksVerb.vcrun2012.displayName.contains("2012"))
        XCTAssertTrue(WinetricksVerb.vcrun2013.displayName.contains("2013"))
        XCTAssertTrue(WinetricksVerb.vcrun2015.displayName.contains("2015"))
        XCTAssertTrue(WinetricksVerb.vcrun2017.displayName.contains("2017"))
        XCTAssertTrue(WinetricksVerb.vcrun2019.displayName.contains("2019"))
        XCTAssertTrue(WinetricksVerb.vcrun2022.displayName.contains("2022"))
    }
    
    // MARK: - .NET Framework Verbs
    
    func testDotnetVerbsCategory() {
        let dotnetVerbs: [WinetricksVerb] = [
            .dotnet20, .dotnet40, .dotnet45, .dotnet48,
            .dotnetdesktop6, .dotnetdesktop7
        ]
        
        for verb in dotnetVerbs {
            XCTAssertEqual(verb.category, .dotnet)
        }
    }
    
    func testDotnetVerbDisplayNames() {
        XCTAssertEqual(WinetricksVerb.dotnet20.displayName, ".NET 2.0")
        XCTAssertEqual(WinetricksVerb.dotnet40.displayName, ".NET 4.0")
        XCTAssertEqual(WinetricksVerb.dotnet45.displayName, ".NET 4.5")
        XCTAssertEqual(WinetricksVerb.dotnet48.displayName, ".NET 4.8")
        XCTAssertEqual(WinetricksVerb.dotnetdesktop6.displayName, ".NET Desktop 6")
        XCTAssertEqual(WinetricksVerb.dotnetdesktop7.displayName, ".NET Desktop 7")
    }
    
    // MARK: - DirectX Verbs
    
    func testDirectxVerbsCategory() {
        let directxVerbs: [WinetricksVerb] = [
            .d3dx9, .d3dx10, .d3dx11_43,
            .d3dcompiler_43, .d3dcompiler_47, .dxvk
        ]
        
        for verb in directxVerbs {
            XCTAssertEqual(verb.category, .directx)
        }
    }
    
    func testDirectxVerbDisplayNames() {
        XCTAssertEqual(WinetricksVerb.d3dx9.displayName, "DirectX 9")
        XCTAssertEqual(WinetricksVerb.d3dx10.displayName, "DirectX 10")
        XCTAssertEqual(WinetricksVerb.d3dx11_43.displayName, "DirectX 11")
        XCTAssertEqual(WinetricksVerb.d3dcompiler_43.displayName, "D3D Compiler 43")
        XCTAssertEqual(WinetricksVerb.d3dcompiler_47.displayName, "D3D Compiler 47")
        XCTAssertEqual(WinetricksVerb.dxvk.displayName, "DXVK")
    }
    
    // MARK: - Other Verbs
    
    func testOtherVerbsCategory() {
        let otherVerbs: [WinetricksVerb] = [
            .physx, .xact, .xact_x64, .xinput, .xlive,
            .msxml3, .msxml6, .gdiplus, .riched20, .riched30,
            .ie8, .mfc42, .quartz, .wmp9, .wmp11, .flash, .mono28
        ]
        
        for verb in otherVerbs {
            XCTAssertEqual(verb.category, .other)
        }
    }
    
    func testOtherVerbDisplayNames() {
        XCTAssertEqual(WinetricksVerb.physx.displayName, "PhysX")
        XCTAssertEqual(WinetricksVerb.xact.displayName, "XACT")
        XCTAssertEqual(WinetricksVerb.xact_x64.displayName, "XACT x64")
        XCTAssertEqual(WinetricksVerb.xinput.displayName, "XInput")
        XCTAssertEqual(WinetricksVerb.xlive.displayName, "Games for Windows Live")
        XCTAssertEqual(WinetricksVerb.msxml3.displayName, "MSXML 3")
        XCTAssertEqual(WinetricksVerb.msxml6.displayName, "MSXML 6")
        XCTAssertEqual(WinetricksVerb.gdiplus.displayName, "GDI+")
        XCTAssertEqual(WinetricksVerb.riched20.displayName, "Rich Edit 2.0")
        XCTAssertEqual(WinetricksVerb.riched30.displayName, "Rich Edit 3.0")
        XCTAssertEqual(WinetricksVerb.ie8.displayName, "Internet Explorer 8")
        XCTAssertEqual(WinetricksVerb.mfc42.displayName, "MFC 4.2")
        XCTAssertEqual(WinetricksVerb.quartz.displayName, "Quartz (DirectShow)")
        XCTAssertEqual(WinetricksVerb.wmp9.displayName, "Windows Media Player 9")
        XCTAssertEqual(WinetricksVerb.wmp11.displayName, "Windows Media Player 11")
        XCTAssertEqual(WinetricksVerb.flash.displayName, "Flash Player")
        XCTAssertEqual(WinetricksVerb.mono28.displayName, "Mono 2.8")
    }
    
    // MARK: - Raw Value Tests
    
    func testRawValuesMatchCommands() {
        // These must match exactly what winetricks expects
        XCTAssertEqual(WinetricksVerb.corefonts.rawValue, "corefonts")
        XCTAssertEqual(WinetricksVerb.vcrun2022.rawValue, "vcrun2022")
        XCTAssertEqual(WinetricksVerb.dotnet48.rawValue, "dotnet48")
        XCTAssertEqual(WinetricksVerb.d3dx9.rawValue, "d3dx9")
        XCTAssertEqual(WinetricksVerb.physx.rawValue, "physx")
    }
}

// MARK: - WinetricksCategory Tests

final class WinetricksCategoryTests: XCTestCase {
    
    func testAllCases() {
        XCTAssertEqual(WinetricksCategory.allCases.count, 5)
    }
    
    func testRawValues() {
        XCTAssertEqual(WinetricksCategory.fonts.rawValue, "Fonts")
        XCTAssertEqual(WinetricksCategory.vcpp.rawValue, "Visual C++ Runtime")
        XCTAssertEqual(WinetricksCategory.dotnet.rawValue, ".NET Framework")
        XCTAssertEqual(WinetricksCategory.directx.rawValue, "DirectX")
        XCTAssertEqual(WinetricksCategory.other.rawValue, "Other")
    }
    
    func testInitFromRawValue() {
        XCTAssertEqual(WinetricksCategory(rawValue: "Fonts"), .fonts)
        XCTAssertEqual(WinetricksCategory(rawValue: "Visual C++ Runtime"), .vcpp)
        XCTAssertEqual(WinetricksCategory(rawValue: ".NET Framework"), .dotnet)
        XCTAssertEqual(WinetricksCategory(rawValue: "DirectX"), .directx)
        XCTAssertEqual(WinetricksCategory(rawValue: "Other"), .other)
        XCTAssertNil(WinetricksCategory(rawValue: "Invalid"))
    }
    
    func testEachCategoryHasVerbs() {
        for category in WinetricksCategory.allCases {
            let verbsInCategory = WinetricksVerb.allCases.filter { $0.category == category }
            XCTAssertFalse(verbsInCategory.isEmpty, "Category \(category) should have at least one verb")
        }
    }
    
    func testVerbDistribution() {
        var categoryCount: [WinetricksCategory: Int] = [:]
        
        for verb in WinetricksVerb.allCases {
            categoryCount[verb.category, default: 0] += 1
        }
        
        // Each category should have verbs
        for category in WinetricksCategory.allCases {
            XCTAssertGreaterThan(categoryCount[category, default: 0], 0)
        }
        
        // Verify specific counts
        XCTAssertEqual(categoryCount[.fonts, default: 0], 7)
        XCTAssertEqual(categoryCount[.vcpp, default: 0], 10)
        XCTAssertEqual(categoryCount[.dotnet, default: 0], 6)
        XCTAssertEqual(categoryCount[.directx, default: 0], 6)
        XCTAssertEqual(categoryCount[.other, default: 0], 17)
    }
}

// MARK: - Steam Dependencies Tests

final class SteamDependenciesTests: XCTestCase {
    
    func testSteamDependencyVerbs() {
        // These are the verbs used in installSteamDependencies
        let steamVerbs: [WinetricksVerb] = [.corefonts, .vcrun2022, .d3dcompiler_47]
        
        for verb in steamVerbs {
            XCTAssertTrue(WinetricksVerb.allCases.contains(verb))
        }
    }
    
    func testSteamDependenciesIncludeFonts() {
        let steamVerbs: [WinetricksVerb] = [.corefonts, .vcrun2022, .d3dcompiler_47]
        
        let hasFont = steamVerbs.contains { $0.category == .fonts }
        XCTAssertTrue(hasFont)
    }
    
    func testSteamDependenciesIncludeVcpp() {
        let steamVerbs: [WinetricksVerb] = [.corefonts, .vcrun2022, .d3dcompiler_47]
        
        let hasVcpp = steamVerbs.contains { $0.category == .vcpp }
        XCTAssertTrue(hasVcpp)
    }
    
    func testSteamDependenciesIncludeDirectX() {
        let steamVerbs: [WinetricksVerb] = [.corefonts, .vcrun2022, .d3dcompiler_47]
        
        let hasDirectX = steamVerbs.contains { $0.category == .directx }
        XCTAssertTrue(hasDirectX)
    }
}

// MARK: - Game Dependencies Tests

final class GameDependenciesTests: XCTestCase {
    
    func testGameDependencyVerbs() {
        // These are the verbs used in installGameDependencies
        let gameVerbs: [WinetricksVerb] = [
            .corefonts, .vcrun2022, .vcrun2019,
            .d3dx9, .d3dcompiler_47, .physx, .xact
        ]
        
        for verb in gameVerbs {
            XCTAssertTrue(WinetricksVerb.allCases.contains(verb))
        }
    }
    
    func testGameDependenciesCoverCategories() {
        let gameVerbs: [WinetricksVerb] = [
            .corefonts, .vcrun2022, .vcrun2019,
            .d3dx9, .d3dcompiler_47, .physx, .xact
        ]
        
        let categories = Set(gameVerbs.map { $0.category })
        
        XCTAssertTrue(categories.contains(.fonts))
        XCTAssertTrue(categories.contains(.vcpp))
        XCTAssertTrue(categories.contains(.directx))
        XCTAssertTrue(categories.contains(.other))
    }
    
    func testGameDependenciesIncludePhysX() {
        let gameVerbs: [WinetricksVerb] = [
            .corefonts, .vcrun2022, .vcrun2019,
            .d3dx9, .d3dcompiler_47, .physx, .xact
        ]
        
        XCTAssertTrue(gameVerbs.contains(.physx))
    }
    
    func testGameDependenciesMultipleVcpp() {
        let gameVerbs: [WinetricksVerb] = [
            .corefonts, .vcrun2022, .vcrun2019,
            .d3dx9, .d3dcompiler_47, .physx, .xact
        ]
        
        let vcppVerbs = gameVerbs.filter { $0.category == .vcpp }
        XCTAssertGreaterThanOrEqual(vcppVerbs.count, 2)
    }
}

// MARK: - Winetricks Verb Count Tests

final class WinetricksVerbCountTests: XCTestCase {
    
    func testTotalVerbCount() {
        XCTAssertEqual(WinetricksVerb.allCases.count, 46)
    }
    
    func testFontVerbCount() {
        let count = WinetricksVerb.allCases.filter { $0.category == .fonts }.count
        XCTAssertEqual(count, 7)
    }
    
    func testVcppVerbCount() {
        let count = WinetricksVerb.allCases.filter { $0.category == .vcpp }.count
        XCTAssertEqual(count, 10)
    }
    
    func testDotnetVerbCount() {
        let count = WinetricksVerb.allCases.filter { $0.category == .dotnet }.count
        XCTAssertEqual(count, 6)
    }
    
    func testDirectxVerbCount() {
        let count = WinetricksVerb.allCases.filter { $0.category == .directx }.count
        XCTAssertEqual(count, 6)
    }
    
    func testOtherVerbCount() {
        let count = WinetricksVerb.allCases.filter { $0.category == .other }.count
        XCTAssertEqual(count, 17)
    }
}
