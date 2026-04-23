import Foundation

extension Bundle {
    var excelTemplateURL: URL? {
        url(forResource: "ExpenseMe Excel", withExtension: "xlsx")
    }
}
