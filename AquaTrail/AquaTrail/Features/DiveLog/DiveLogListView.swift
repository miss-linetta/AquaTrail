//
//  DiveLogListView.swift
//  AquaTrail
//

import SwiftUI

struct DiveLogListView: View {
    @Environment(AuthViewModel.self) private var authVM
    @State private var vm = DiveLogViewModel()
    @State private var showAuth = false

    var body: some View {
        NavigationStack {
            Group {
                if !authVM.isAuthenticated {
                    notAuthenticatedView
                } else if vm.isLoading {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if vm.logs.isEmpty {
                    emptyStateView
                } else {
                    logsList
                }
            }
            .background(Color.navyDeep)
            .navigationTitle("Dive Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        DiveLogFormView()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.skyLight)
                    }
                    .opacity(authVM.isAuthenticated ? 1 : 0)
                    .disabled(!authVM.isAuthenticated)
                }
            }
            .task(id: authVM.isAuthenticated) {
                if authVM.isAuthenticated {
                    await vm.load()
                }
            }
            .refreshable {
                await vm.load()
            }
            .onChange(of: authVM.isAuthenticated) { _, isAuth in
                if isAuth {
                    showAuth = false
                    Task { await vm.load() }
                } else {
                    vm.logs = []
                }
            }
            .fullScreenCover(isPresented: $showAuth) {
                NavigationStack {
                    AuthView(vm: authVM)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button { showAuth = false } label: {
                                    Image(systemName: "xmark")
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                }
            }
        }
    }

    // MARK: – Not authenticated

    private var notAuthenticatedView: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.skyLight.opacity(0.5))

                Text("Sign in to keep a dive log")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Button { showAuth = true } label: {
                    Text("Sign in")
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.navyDeep)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(Color.skyLight)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 120)
        }
    }

    // MARK: – Empty state

    private var emptyStateView: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "water.waves")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.skyLight.opacity(0.5))

                Text("No records yet")
                    .font(.headline)
                    .foregroundStyle(.white)

                Text("Add your first dive")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))

                NavigationLink {
                    DiveLogFormView()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                        Text("Add dive")
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.navyDeep)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(Color.skyLight)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 120)
        }
    }

    // MARK: – Stats header

    private var statsHeader: some View {
        HStack(spacing: 0) {
            statItem(value: "\(vm.totalDives)", label: "Dives")
            statItem(
                value: vm.averageDepth.map { "\(Int($0.rounded()))" } ?? "—",
                label: "Avg. depth"
            )
            statItem(value: "\(vm.totalBottomTime)", label: "Minutes")
            statItem(
                value: vm.averageRating.map { String(format: "%.1f", $0) } ?? "—",
                label: "Avg. rating"
            )
        }
        .padding(12)
        .background(Color.deepTeal)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
    }

    private func statItem(value: String, label: LocalizedStringKey) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(Color.skyLight)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: – Logs list

    private var logsList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                statsHeader

                ForEach(vm.logs) { log in
                    NavigationLink {
                        DiveLogDetailView(log: log, displaySpotName: vm.localizedSpotName(for: log))
                    } label: {
                        logRow(log)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            Task { await vm.delete(log) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.vertical, 16)
        }
    }

    private func logRow(_ log: DiveLog) -> some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.deepTeal)
                    .frame(width: 48, height: 48)
                Image(systemName: "water.waves")
                    .font(.body)
                    .foregroundStyle(Color.skyLight)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(vm.localizedSpotName(for: log))
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)

                HStack(spacing: 12) {
                    Text(log.dateValue, style: .date)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))

                    if let rating = log.rating, rating > 0 {
                        HStack(spacing: 1) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .font(.system(size: 8))
                                    .foregroundStyle(star <= rating ? Color.skyLight : .white.opacity(0.3))
                            }
                        }
                    }
                }
            }

            Spacer()

            // Stats
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(log.depth) m")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                Text("\(log.duration) min")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.3))
        }
        .padding(14)
        .background(Color.deepTeal.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
    }
}
