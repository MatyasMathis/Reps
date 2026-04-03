//
//  YearShareSheet.swift
//  Reps
//
//  Purpose: Share sheet for Year in Pixels cards with background mode picker
//  Design: SOLID / CLEAR / PHOTO modes, Strava-inspired
//

import SwiftUI
import UIKit
import PhotosUI

/// Sheet for customizing and sharing the Year in Pixels heatmap card.
///
/// User can choose solid, transparent, or photo background, preview
/// the card live, and share or save it.
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

    private var shareBackground: ShareBackground {
        switch bgMode {
        case .solid: return .solid
        case .transparent: return .transparent
        case .photo: return selectedPhoto.map { .photo($0) } ?? .solid
        }
    }

    private var cardView: ShareableYearCard {
        ShareableYearCard(
            selectedYear: selectedYear,
            monthRows: monthRows,
            monthNames: monthNames,
            totalCompletions: totalCompletions,
            activeDays: activeDays,
            longestStreak: longestStreak,
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
                    Text("SHARE YEAR")
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
                    .background(bgMode == mode ? Color.recoveryGreen : Color.clear)
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
                .background(Color.recoveryGreen)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.standard))
            }
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
