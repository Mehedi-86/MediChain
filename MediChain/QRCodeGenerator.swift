//
//  QRCodeGenerator.swift
//  MediChain


import SwiftUI
import CoreImage.CIFilterBuiltins

class QRCodeGenerator {
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()

    func generateQRCode(from string: String) -> UIImage {
        // Convert the string into data the filter can read
        filter.message = Data(string.utf8)

        if let outputImage = filter.outputImage {
            if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgimg)
            }
        }

        // Return a red X if something goes wrong
        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
}
