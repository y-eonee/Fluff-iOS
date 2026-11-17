import SwiftUI

struct CouchFlowView: View {
    @Bindable var session: CouchSession
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @State private var link = ""
    @State private var selected: CouchVideo?
    @State private var tab = 0
    @State private var linkError: String?
    @State private var accountActions = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                D1IconButton(icon: "back", label: "방으로 돌아가기") { dismiss() }
                Spacer()
                Text("couch time").notCliche(28, relativeTo: .title).tracking(-1.12)
                Spacer()
                Color.clear.frame(width: 44, height: 44)
            }.padding(.horizontal, 20).padding(.top, 10).padding(.bottom, 4)
            if session.choosing { picker }
            else { watching }
        }.foregroundStyle(Color.mib.text.primary).background(Color.mib.bg.screen)

            .task {
                #if DEBUG
                if ProcessInfo.processInfo.arguments.contains(where: { $0.hasPrefix("--design-preview=") }) {
                    if ProcessInfo.processInfo.arguments.contains("--design-preview=couch-playlist") { selected = session.library.videos.first }
                    return
                }
                #endif
                await session.account.restore()
            }
            .onChange(of: scenePhase) { _, phase in if phase != .active { session.player.pause() } }
            .confirmationDialog("YouTube 계정", isPresented: $accountActions, titleVisibility: .visible) {
                Button("플레이리스트 다시 불러오기") { Task { await session.account.refresh() } }
                Button("연결 해제", role: .destructive) {
                    selected = nil
                    Task { await session.account.disconnect() }
                }
                Button("취소", role: .cancel) {}
            } message: { Text(session.account.email ?? "") }
            .alert("YouTube 계정 연결", isPresented: Binding(get: { session.account.message != nil }, set: { if !$0 { session.account.message = nil } })) {
                Button("확인", role: .cancel) { session.account.message = nil }
            } message: { Text(session.account.message ?? "") }
    }
    private var candidates: [CouchVideo] {
        switch tab {
        case 1: return session.library.videos.filter { $0.lastWatched != nil && !$0.source.isPlaylist }.sorted { ($0.lastWatched ?? .distantPast) > ($1.lastWatched ?? .distantPast) }
        case 2: return session.library.videos.filter(\.favorite)
        default:
            let owned = Set(session.account.playlists.map(\.id))
            return session.account.playlists + session.library.videos.filter { !owned.contains($0.id) }
        }
    }
    private var picker: some View {
        VStack(spacing: 16) {
            accountCard.offset(y: 6).padding(.horizontal, 16)
            VStack(spacing: 8) {
                HStack(spacing: 0) {
                    ForEach(Array(["내 플레이리스트", "최근 본 영상", "같이 보기 좋은"].enumerated()), id: \.offset) { index, title in
                        Button { tab = index } label: {
                            Text(title).pretendard(.regular, 13).frame(maxWidth: .infinity, minHeight: 36)
                                .overlay(alignment: .bottom) { Rectangle().fill(tab == index ? Color.rep4.c03 : Color.rep4.c07).frame(height: tab == index ? 1 : 0.5) }
                        }.buttonStyle(.plain).accessibilityAddTraits(tab == index ? .isSelected : [])
                    }
                }
                ScrollView {
                    if candidates.isEmpty {
                        Text(tab == 2 ? "함께 보고 싶은 영상에 하트를 눌러 주세요" : tab == 1 ? "함께 본 영상이 여기에 모여요" : "계정을 연결하거나 유튜브 링크를 추가해 주세요")
                            .pretendard(.regular, 14).foregroundStyle(Color.rep4.c29).multilineTextAlignment(.center).padding(.vertical, 48)
                    }
                    LazyVStack(spacing: 8) { ForEach(candidates) { video in videoRow(video) } }
                }.scrollIndicators(.hidden)
                HStack(spacing: 6) {
                    Image("rep4_couch_playlist").resizable().frame(width: 14.149, height: 12.561)
                    TextField("", text: $link, prompt: Text("유튜브 플레이리스트 링크 붙여넣기").foregroundColor(Color.rep4.c03))
                        .textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL).submitLabel(.go).onSubmit(addLink)
                    if !link.isEmpty { Button(action: addLink) { Image(systemName: "plus").frame(width: 44, height: 44) }.accessibilityLabel("링크 추가") }
                }.pretendard(.regular, 14).frame(minHeight: 60).padding(.horizontal, 14)
                if let linkError { Text(linkError).pretendard(.regular, 12).foregroundStyle(Color.mib.semantic.error) }
            }.padding(8).background(Color.rep4.c01, in: RoundedRectangle(cornerRadius: 22)).padding(.horizontal, 16)
            Button("소파에서 같이 보기") {
                if let selected { session.watch(session.library.videos.first { $0.id == selected.id } ?? selected) }
            }.buttonStyle(D1PrimaryStyle()).disabled(selected == nil).padding(.horizontal, 22).padding(.top, 10).padding(.bottom, -2)
        }
    }
    private var accountCard: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(Color(uiColor: Palette.uiColor("#F25454"))).frame(width: 40, height: 34)
                Image("couch_youtube_play").resizable().scaledToFit().frame(width: 16, height: 16)
            }.accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(session.account.isConnected ? "YouTube 계정 연결됨" : "YouTube 계정 연결")
                    .pretendard(.regular, 14, tracking: -0.7).frame(height: 20.3)
                Text(session.account.isLoading ? "플레이리스트를 불러오고 있어요" : session.account.isConnected ? "내 플레이리스트 \(session.account.playlists.count)개를 불러왔어요" : "내 플레이리스트를 함께 볼 수 있어요")
                    .pretendard(.regular, 14, tracking: -0.7).frame(height: 20.3)
            }
            Spacer(minLength: 0)
            if session.account.isLoading { ProgressView() }
            else {
                Button(session.account.isConnected ? "변경" : "연결") {
                    if session.account.isConnected { accountActions = true }
                    else { Task { await session.account.connect() } }
                }.pretendard(.regular, 14, tracking: -0.7).underline().frame(minWidth: 44, minHeight: 44)
            }
        }.padding(.horizontal, 16).frame(minHeight: 66)
    }
    private func videoRow(_ video: CouchVideo) -> some View {
        Button { selected = video } label: {
            HStack(spacing: 12) {
                AsyncImage(url: video.thumbnailURL) { image in image.resizable().scaledToFill() } placeholder: {
                    ZStack { Color.mib.bg.mintSoft; Image(systemName: "play.rectangle").foregroundStyle(Color.mib.text.secondary) }
                }.frame(width: 96, height: 54).clipShape(RoundedRectangle(cornerRadius: 8))
                VStack(alignment: .leading, spacing: 5) {
                    Text(video.title).pretendard(.regular, 14, tracking: -0.7).lineLimit(2)
                    Text(video.videoCount.map { "영상 \($0)개" } ?? (video.source.isPlaylist ? "플레이리스트" : "YouTube 영상"))
                        .pretendard(.regular, 14, tracking: -0.7)
                }
                Spacer(minLength: 0)
                if selected?.id == video.id { D1Icon(name: "check") }
            }.padding(10).frame(maxWidth: .infinity, alignment: .leading)
                .modifier(RepresentativeSelectionSurface(selected: selected?.id == video.id, radius: 14, neutral: Color.rep4.c11))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(selected?.id == video.id ? Color.mib.line.selected : Color.mib.line.default, lineWidth: selected?.id == video.id ? 2 : 1))
        }.buttonStyle(.plain).accessibilityAddTraits(selected?.id == video.id ? .isSelected : [])
    }
    private func addLink() {
        guard let source = YouTubeSource.parse(link) else { linkError = "YouTube 영상 또는 플레이리스트 링크를 확인해 주세요."; return }
        selected = session.library.add(source); link = ""; linkError = nil; tab = 0
        Task { await session.library.resolveTitle(for: source) }
    }
    private var watching: some View {
        VStack(spacing: 12) {
            ScrollView {
                VStack(spacing: -6) {
                    CouchCompanionPreview(dolls: session.dolls)
                    VStack(spacing: 22.23) {
                        // Render the live player at its supported layout size, then fit it
                        // into the original 184-point video slot without cropping controls.
                        GeometryReader { geometry in
                            YouTubePlayerView(player: session.player)
                                .frame(width: geometry.size.width / 0.92, height: 200)
                                .scaleEffect(0.92, anchor: .topLeading)
                        }.frame(height: 184)
                            .overlay {
                                if !session.player.ready {
                                    CouchLoadingArtwork(title: session.current?.title ?? "YouTube", failed: session.player.error != nil)
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        playbackControls
                        HStack {
                            Button { session.player.pause(); selected = session.current; session.choosing = true } label: {
                                HStack(spacing: 6) {
                                    Image("rep4_couch_playlist").resizable().frame(width: 14.149, height: 12.561)
                                    Text("플레이리스트 변경").pretendard(.regular, 14)
                                }.frame(maxWidth: .infinity, minHeight: 46)
                            }
                        }.buttonStyle(.plain)
                            .contextMenu {
                                if let video = session.current {
                                    Button(session.library.favorite(video) ? "즐겨찾기에서 제거" : "같이 보기 좋은 영상에 추가") { session.library.toggleFavorite(video) }
                                }
                            }
                        if let error = session.player.error {
                            Text(error).pretendard(.regular, 13)
                            HStack {
                                Button("다시 시도") { if let source = session.current?.source { session.player.load(source) } }
                                Button("YouTube에서 열기") { if let url = session.current?.source.url { session.player.pause(); openURL(url) } }
                            }.pretendard(.medium, 13)
                        }
                    }.padding(15).frame(minHeight: 364, alignment: .top).background(Color.rep4.c01, in: RoundedRectangle(cornerRadius: 21))
                }.padding(.horizontal, 16)
            }.scrollIndicators(.hidden)
            Button("홈에서 계속 보기") { dismiss() }.modifier(RepresentativeActionSurface(height: 46)).padding(.horizontal, 24)
            Button("그만 보기") { session.stop(); dismiss() }.pretendard(.medium, 12).underline().foregroundStyle(Color.rep4.c29).frame(minHeight: 44).padding(.top, -10)
        }
    }
    private var playbackControls: some View {
        HStack(spacing: 22.23) {
            Spacer()
            Button { session.player.previous() } label: {
                Image("rep4_couch_previous").scaleEffect(x: -1, y: 1).frame(width: 16.09, height: 15.94).frame(width: 44, height: 44).background(Color.rep4.c28, in: Circle())
            }.disabled(session.player.count < 2 || !session.player.ready).accessibilityLabel("이전 영상")
            Button { session.player.toggle() } label: {
                if session.player.playing {
                    Image("rep4_couch_pause").resizable().frame(width: 58.46, height: 58.46)
                } else {
                    D1PlaybackGlyph(paused: true).frame(width: 58.46, height: 58.46).background(Color.rep4.c30, in: Circle())
                }
            }.disabled(!session.player.ready).accessibilityLabel(session.player.playing ? "일시정지" : "재생")
            Button { session.player.next() } label: {
                Image("rep4_couch_next").frame(width: 16.09, height: 15.94).frame(width: 44, height: 44).background(Color.rep4.c28, in: Circle())
            }.disabled(session.player.count < 2 || !session.player.ready).accessibilityLabel("다음 영상")
            Spacer()
        }.buttonStyle(.plain).foregroundStyle(Color.rep4.c03)
    }
    private func time(_ value: Double) -> String { let seconds = Int(max(0, value)); return String(format: "%d:%02d", seconds / 60, seconds % 60) }
}

/// The source player artwork remains visible while the live video is loading.
/// It never replaces a ready YouTube player or fabricates playback progress.
private struct CouchLoadingArtwork: View {
    let title: String
    let failed: Bool
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                RepresentativeGradientFill(definition: RepresentativeGradients.video)
                Image("rep4_couch_video_art_moon").resizable().frame(width: 54, height: 54)
                    .offset(x: geometry.size.width - 67, y: 34)
                Image("rep4_couch_video_art_hill").resizable().frame(width: 520, height: 180)
                    .offset(x: -80, y: 140)
                VStack(alignment: .leading, spacing: 5) {
                    Text(title).pretendard(.bold, 15).lineLimit(1)
                    HStack(spacing: 6) {
                        Image("couch_youtube_play").resizable().frame(width: 8, height: 8)
                            .frame(width: 20, height: 14)
                            .background(Color(uiColor: Palette.uiColor("#F25454")), in: RoundedRectangle(cornerRadius: 4))
                        Text(failed ? "YouTube · 재생을 확인해 주세요" : "YouTube · 영상을 불러오는 중")
                            .pretendard(.regular, 12)
                    }
                }.padding(16)
            }.frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
                .foregroundStyle(Color.rep4.c08).clipped()
        }.allowsHitTesting(false)
    }
}

struct CouchCompanionPreview: View {
    let dolls: [DollState]
    var body: some View {
        ZStack(alignment: .bottom) {
            Image("rep4_couch_sofa").resizable().scaledToFill()
                .frame(width: 336, height: 139).clipped().offset(x: 4.5)
            CompanionScene(dolls: Array(dolls.prefix(1)), kind: .couch)
                .renderedOnlyWhileVisible(background: .clear).frame(height: 250).offset(y: -21)
        }.frame(height: 240).clipped()
            .accessibilityLabel("선택한 인형이 앉은 소파")
    }
}

struct CouchMiniPlayer: View {
    let session: CouchSession
    let open: () -> Void
    var body: some View {
        GeometryReader { geometry in
            // Keep the embedded player's minimum 200-point viewport, then fit
            // that live surface into the source's compact 200 × 112 slot.
            let scale = geometry.size.height / 200
            YouTubePlayerView(player: session.player)
                .frame(width: geometry.size.width / scale, height: 200)
                .scaleEffect(scale, anchor: .topLeading)
        }.overlay {
            if !session.player.ready {
                CouchLoadingArtwork(title: session.current?.title ?? "YouTube", failed: session.player.error != nil)
            }
        }.clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.white, lineWidth: 4))
            .accessibilityAction(named: "소파에서 크게 보기", open)
            .contextMenu {
                Button("소파에서 크게 보기", action: open)
                Button("그만 보기") { session.stop() }
            }
    }
}

struct CouchMiniControls: View {
    let session: CouchSession
    let open: () -> Void
    var body: some View {
        HStack(spacing: 8) {
            Button(action: open) {
                HStack(spacing: 8) {
                    HStack(alignment: .bottom, spacing: 3) {
                        ForEach([10.0, 15.0, 8.0], id: \.self) { height in
                            Capsule().fill(Color.rep4.c21).frame(width: 3, height: height)
                        }
                    }.frame(width: 16, height: 16)
                    Text("\(session.player.title.isEmpty ? session.current?.title ?? "YouTube" : session.player.title) · \(FocusSession.clock(session.player.elapsed, hours: false))")
                        .pretendard(.regular, 14, tracking: -0.7).lineLimit(1)
                }.frame(maxWidth: .infinity, alignment: .leading)
            }.accessibilityLabel("소파에서 크게 보기")
            Button { session.player.toggle() } label: {
                D1PlaybackGlyph(paused: !session.player.playing).scaleEffect(0.43)
                    .frame(width: 33, height: 33).background(Color.rep4.c30, in: RoundedRectangle(cornerRadius: 14))
            }.disabled(!session.player.ready).accessibilityLabel(session.player.playing ? "일시정지" : "재생")
        }.buttonStyle(.plain).padding(.leading, 12).padding(.trailing, 4)
            .frame(height: 48).background(Color.rep4.c27, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color(uiColor: Palette.uiColor("#E8DDCB")), lineWidth: 1))
            .contextMenu { Button("그만 보기") { session.stop() } }
    }
}
