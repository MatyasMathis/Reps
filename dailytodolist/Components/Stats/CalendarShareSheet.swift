//
//  CalendarShareSheet.swift
//  Reps
//
//  Purpose: Share sheet for category calendar cards with background mode picker
//  Design: SOLID / CLEAR / PHOTO modes, Strava-inspired
//

import SwiftUI
import UIKit
import PhotosUI

/// Sheet for customizing and sharing a category's monthly completion calendar.
///
/// User can choose solid, transparent, or photo background, preview
/// the card live, and share or save it.
struct CalendarShareSheet: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    let categoryName: String
    let categoryIcon: String
    let categoryColorHex: String
    let completionDates: Set<Date>
    let displayedMonth: Date
    let streak: Int
    let completionCount: Int

    // MARK: - State

    @State private var bgMode: BGMode = .solid
    @State private var selectedPhoto: UIImage?
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var showCamera = false

    // MARK: - Background mode

    private enum BGMode: CaseIterable {
        case solid, transparent, photo
        var label: String {
            switch self {
            case .solid: "SOLID"
            case .transparent: "CLEAR"
            case .photo: "PHOTO"
            }
        }
        var icon: String {
            switch self {
            case .solid: "rectangle.fill"
            case .transparent: "square.dashed"
            case .photo: "photo.fill"
            }
        }
    }

    private var categoryColor: Color { Color(hex: categoryColorHex) }

    private var shareBackground: ShareBackground {
        switch bgMode {
        case .solid: return .solid
        case .transparent: return .transparent
        case .photo: return selectedPhoto.map { .photo($0) } ?? .solid
        }
    }

    private var cardView: ShareableCalendarCard {
        ShareableCalendarCard(
            categoryName: categoryName,
            categoryIcon: categoryIcon,
            categoryColorHex: categoryColorHex,
            completionDates: completionDates,
            displayedMonth: displayedMonth,
            streak: streak,
            completionCount: completionCount,
            background: shareBackground
        )
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.brandBlack.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Card preview
                    cardPreview
                        .padding(.top, Spacing.lg)

                    Spacer()

                    // Photo pickers (only in photo mode)
                    if bgMode == .photo {
                        photoPickerButtons
                            .padding(.bottom, Spacing.lg)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    // Background mode selector
                    bgModeSelector
                        .padding(.horizontal, Spacing.xl)
                        .padding(.bottom, Spacing.md)

                    // Action buttons
                    actionButtons
                        .padding(.horizontal, Spacing.xl)
                        .padding(.bottom, Spacing.xxl)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: bgMode)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color.pureWhite)
                            .frame(width: 36, height: 36)
                            .background(Color.darkGray1)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }

                ToolbarItem(placement: .principal) {
                    Text("SHARE CALENDAR")
                        .font(.system(size: 15, weight: .black))
                        .italic()
                        .foregroundStyle(Color.pureWhite)
                }
            }
            .toolbarBackground(Color.brandBlack, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onChange(of: photosPickerItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedPhoto = image
                    }
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraView(image: $selectedPhoto)
                    .ignoresSafeArea()
            }
        }
    }

    // MARK: - Subviews

    private var cardPreview: some View {
        cardView
            .frame(width: 1080, height: 1920)
            .scaleEffect(0.22)
            .frame(width: 1080 * 0.22, height: 1920 * 0.22)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
            .shadowLevel1()
    }

    private var bgModeSelector: some View {
        HStack(spacing: 0) {
            ForEach(BGMode.allCases, id: \.label) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { bgMode = mode }
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 12, weight: .bold))
                        Text(mode.label)
                            .font(.system(size: 12, weight: .bold))
                            .tracking(0.5)
                    }
                    .foregroundStyle(bgMode == mode ? Color.brandBlack : Color.mediumGray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .background(bgMode == mode ? categoryColor : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.standard - 2))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.darkGray1)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.standard))
    }

    private var photoPickerButtons: some View {
        HStack(spacing: Spacing.md) {
            // Camera
            Button { showCamera = true } label: {
                VStack(spacing: Spacing.xs) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 20, weight: .semibold))
                    Text("CAMERA")
                        .font(.system(size: Typography.captionSize, weight: .bold))
                        .tracking(0.5)
                }
                .foregroundStyle(Color.pureWhite)
                .frame(width: 80, height: 64)
                .background(Color.darkGray1)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.standard))
            }

            // Gallery
            PhotosPicker(selection: $photosPickerItem, matching: .images) {
                VStack(spacing: Spacing.xs) {
                    Image(systemName: "photo.fill")
                        .font(.system(size: 20, weight: .semibold))
                    Text("GALLERY")
                        .font(.system(size: Typography.captionSize, weight: .bold))
                        .tracking(0.5)
                }
                .foregroundStyle(Color.pureWhite)
                .frame(width: 80, height: 64)
                .background(Color.darkGray1)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.standard))
            }

            // Remove photo
            if selectedPhoto != nil {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedPhoto = nil
                        photosPickerItem = nil
                    }
                } label: {
                    VStack(spacing: Spacing.xs) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                        Text("REMOVE")
                            .font(.system(size: Typography.captionSize, weight: .bold))
                            .tracking(0.5)
                    }
                    .foregroundStyle(Color.strainRed)
                    .frame(width: 80, height: 64)
                    .background(Color.darkGray1)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.standard))
                }
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: Spacing.md) {
            // Save to Photos
            Button {
                let card = cardView
                Task { @MainActor in
                    if let image = ShareService.renderImage(from: card, size: CGSize(width: 1080, height: 1920)) {
                        ShareService.saveToPhotos(image: image)
                    }
                }
            } label: {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 14, weight: .bold))
                    Text("SAVE")
                        .font(.system(size: Typography.bodySize, weight: .bold))
                        .tracking(0.5)
                }
                .foregroundStyle(Color.pureWhite)
                .frame(maxWidth: .infinity)
                .frame(height: ComponentSize.buttonHeight)
                .background(Color.darkGray1)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.standard))
            }

            // Share
            Button {
                ShareService.renderAndShare(
                    view: cardView,
                    size: CGSize(width: 1080, height: 1920)
                )
            } label: {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .bold))
                    Text("SHARE")
                        .font(.system(size: Typography.bodySize, weight: .bold))
                        .tracking(0.5)
                }
                .foregroundStyle(Color.brandBlack)
                .frame(maxWidth: .infinity)
                .frame(height: ComponentSize.buttonHeight)
                .background(categoryColor)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.standard))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let calendar = Calendar.current
    var dates: Set<Date> = []
    for daysAgo in [0, 1, 2, 3, 5, 8, 10, 12, 15, 18, 20] {
        if let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) {
            dates.insert(calendar.startOfDay(for: date))
        }
    }

    return CalendarShareSheet(
        categoryName: "Health",
        categoryIcon: "heart.fill",
        categoryColorHex: "2DD881",
        completionDates: dates,
        displayedMonth: Date(),
        streak: 4,
        completionCount: 11
    )
}
