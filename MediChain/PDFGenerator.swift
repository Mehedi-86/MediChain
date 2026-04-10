import SwiftUI

@MainActor
class PDFGenerator {
    
    static func generateReport(extractedText: String, fdaDetails: FDADrugDetail?, medicineName: String) -> URL? {
        // 1. Create the view we want to print
        let reportView = MedicalReportView(
            extractedText: extractedText,
            fdaDetails: fdaDetails,
            medicineName: medicineName
        )
        
        // 2. Tell SwiftUI to render it
        let renderer = ImageRenderer(content: reportView)
        
        // 3. Create a temporary file path on the iPhone
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("MediChain_Report.pdf")
        
        // 4. Draw the view into the PDF file
        renderer.render { size, context in
            var box = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            
            guard let pdf = CGContext(url as CFURL, mediaBox: &box, nil) else {
                return
            }
            
            pdf.beginPDFPage(nil)
            context(pdf)
            pdf.endPDFPage()
            pdf.closePDF()
        }
        
        // 5. Return the URL so we can share it
        return url
    }
}
