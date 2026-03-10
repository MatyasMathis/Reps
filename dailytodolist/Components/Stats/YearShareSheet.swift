//
//  YearShareSheet.swift
//  Reps
//
//  Purpose: Share sheet for Year in Pixels cards with photo picker
//  Design: Photo background option, matching existing share sheet pattern
//

import SwiftUI
import UIKit
import PhotosUI

/// Sheet for customizing and sharing the Year in Pixels heatmap card.
///
/// User can pick a background photo (camera or gallery), preview
/// the card live, and share via the system share sheet.
struct YearShareSheet: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    let selectedYear: Int
    let monthRows: [[DayInfo]]
    let monthNames: [String]
    let totalCompletions: Int
    let activeDays: Int
    let longestStreak: Int

    // MARK: - State

    @State private var selectedPhoto: UIImage?
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var showCamera = false

    // MARK: - Computed

    private var cardView: ShareableYearCard {
        ShareableYearCard(
            selectedYear: selectedYear,
            monthRows: monthRows,
            monthNames: monthNames,
            totalCompletions: totalCompletions,
            activeDays: activeDays,
            longestStreak: longestStreak,
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
                    Text("Share Year")
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
            .background(Color.recoveryGreen)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.standard))
        }
    }
}

// MARK: - Preview

#Preview {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let currentYear = calendar.component(.year, from: Date())

    var completionsByDate: [Date: Int] = [:]
    for i in stride(from: 0, through: 180, by: 1) where Int.random(in: 0...3) > 0 {
        if let d = calendar.date(byAdding: .day, value: -i, to: today) {
            completionsByDate[calendar.startOfDay(for: d)] = Int.random(in: 1...5)
        }
    }

    let monthRows: [[DayInfo]] = (1...12).map { month in
        var comps = DateComponents()
        comps.year = currentYear
        comps.month = month
        comps.day = 1
        guard let monthStart = calendar.date(from: comps),
              let range = calendar.range(of: .day, in: .month, for: monthStart) else { return [] }
        return range.map { day -> DayInfo in
            comps.day = day
            guard let date = calendar.date(from: comps) else { return DayInfo.empty }
            let start = calendar.startOfDay(for: date)
            return DayInfo(date: start, completionCount: completionsByDate[start] ?? 0,
                           isFuture: start > today, isToday: start == today)
        }
    }

    let formatter = DateFormatter()
    formatter.dateFormat = "MMM"
    let monthNames: [String] = (1...12).compactMap { month in
        var comps = DateComponents()
        comps.year = currentYear
        comps.month = month
        comps.day = 1
        guard let date = calendar.date(from: comps) else { return nil }
        return formatter.string(from: date)
    }

    return YearShareSheet(
        selectedYear: currentYear,
        monthRows: monthRows,
        monthNames: monthNames,
        totalCompletions: 342,
        activeDays: 87,
        longestStreak: 14
    )
}
