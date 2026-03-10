//
//  CalendarShareSheet.swift
//  Reps
//
//  Purpose: Share sheet for category calendar cards with photo picker
//  Design: Strava-inspired — photo background option, matching existing share sheet pattern
//

import SwiftUI
import UIKit
import PhotosUI

/// Sheet for customizing and sharing a category's monthly completion calendar.
///
/// User can pick a background photo (camera or gallery), preview
/// the card live, and share via the system share sheet.
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

    @State private var selectedPhoto: UIImage?
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var showCamera = false

    // MARK: - Computed

    private var categoryColor: Color { Color(hex: categoryColorHex) }

    private var cardView: ShareableCalendarCard {
        ShareableCalendarCard(
            categoryName: categoryName,
            categoryIcon: categoryIcon,
            categoryColorHex: categoryColorHex,
            completionDates: completionDates,
            displayedMonth: displayedMonth,
            streak: streak,
            completionCount: completionCount,
            backgroundImage: selectedPhoto
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

                    // Photo source buttons
                    photoButtons
                        .padding(.bottom, Spacing.xl)

                    // Share button
                    shareButton
                        .padding(.horizontal, Spacing.xl)
                        .padding(.bottom, Spacing.xxl)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: Typography.bodySize, weight: .semibold))
                            .foregroundStyle(Color.mediumGray)
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text("Share Calendar")
                        .font(.system(size: Typography.h4Size, weight: .bold))
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

    private var photoButtons: some View {
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
                .background(Color.darkGray2)
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
                .background(Color.darkGray2)
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
                    .background(Color.darkGray2)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.standard))
                }
            }
        }
    }

    private var shareButton: some View {
        Button {
            ShareService.renderAndShare(
                view: cardView,
                size: CGSize(width: 1080, height: 1920)
            )
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 14, weight: .bold))
                Text("Share")
                    .font(.system(size: Typography.bodySize, weight: .bold))
            }
            .foregroundStyle(Color.onAccent)
            .frame(maxWidth: .infinity)
            .frame(height: ComponentSize.buttonHeight)
            .background(categoryColor)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.standard))
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
