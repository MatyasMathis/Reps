//
//  ShareService.swift
//  Reps
//
//  Purpose: Renders SwiftUI views to images and presents the share sheet
//

import SwiftUI
import UIKit

/// Handles rendering SwiftUI views to images and presenting the system share sheet
@MainActor
enum ShareService {

    /// Renders a SwiftUI view to a UIImage at the specified size
    @MainActor
    static func renderImage<V: View>(from view: V, size: CGSize) -> UIImage? {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2.0 // 2x for high quality without being too large
        renderer.proposedSize = .init(size)
        return renderer.uiImage
    }

    /// Presents the system share sheet with the given image
    @MainActor
    static func share(image: UIImage) {
        let activityVC = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )

        // Find the top-most view controller to present from
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            return
        }

        // Walk to the top-most presented controller
        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }

        // iPad requires a popover source
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = topVC.view
            popover.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        topVC.present(activityVC, animated: true)
    }

    /// Convenience: render a view and immediately share it
    @MainActor
    static func renderAndShare<V: View>(view: V, size: CGSize) {
        guard let image = renderImage(from: view, size: size) else { return }
        share(image: image)
    }

    /// Saves an image directly to the user's photo library
    @MainActor
    static func saveToPhotos(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
}
