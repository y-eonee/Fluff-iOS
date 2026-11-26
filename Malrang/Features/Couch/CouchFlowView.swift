import SwiftUI

struct CouchFlowView: View {
    @Bindable var session: CouchSession
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var link = ""
    @State private var selected: CouchVideo?
    @State private var tab = 0
    @State private var linkError: String?

    var body: some View {
        VStack(spacing: 0) {
            FlowHeader(title: "플레이리스트", backLabel: "홈에서 계속 보기") { dismiss() }
            picker
        }.foregroundStyle(Color.rep4.c08).background(FlowDesign.canvas.ignoresSafeArea())
            .environment(\.updatedFlowDesign, true)
            .onAppear {
                selected = session.current; session.player.pause()
                #if DEBUG
                if ProcessInfo.processInfo.arguments.contains("--design-preview=couch-playlist") { selected = session.library.videos.first }
                #endif
            }
            .onChange(of: scenePhase) { _, phase in if phase != .active { session.player.pause() } }
    }
    private var candidates: [CouchVideo] {
        switch tab {
        case 1: return session.library.videos.filter { $0.lastWatched != nil && !$0.source.isPlaylist }.sorted { ($0.lastWatched ?? .distantPast) > ($1.lastWatched ?? .distantPast) }
        case 2: return session.library.videos.filter(\.favorite)
        default: return session.library.videos
        }
    }
    private var picker: some View {
        VStack(spacing: 14) {
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
                        Text(tab == 2 ? "함께 보고 싶은 영상에 하트를 눌러 주세요" : tab == 1 ? "함께 본 영상이 여기에 모여요" : "아래에 유튜브 링크를 추가해 주세요")
                            .pretendard(.regular, 14).foregroundStyle(Color.rep4.c29).multilineTextAlignment(.center).padding(.vertical, 48)
                    }
                    LazyVStack(spacing: 8) { ForEach(candidates) { video in videoRow(video) } }
                }.scrollIndicators(.hidden)
            }.padding(6).background(Color.rep4.c01, in: RoundedRectangle(cornerRadius: 21)).padding(.horizontal, 16).padding(.top, 16)
            HStack(spacing: 8) {
                Image("rep4_couch_playlist").resizable().frame(width: 18.3, height: 16.25)
                    .accessibilityHidden(true)
                TextField("", text: $link, prompt: Text("유튜브 플레이리스트 링크 붙여넣기")
                    .foregroundStyle(Color.mib.text.secondary))
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL)
                    .submitLabel(.go).onSubmit(addLink)
                    .accessibilityLabel("유튜브 플레이리스트 링크 붙여넣기")
                if !link.isEmpty {
                    Button(action: addLink) { Image(systemName: "plus").frame(width: 44, height: 44) }
                        .accessibilityLabel("링크 추가")
                }
            }.pretendard(.medium, 14).padding(.horizontal, 16).frame(height: 60)
                .background(.white, in: Capsule()).padding(.horizontal, 22)
            if let linkError { Text(linkError).pretendard(.regular, 12).foregroundStyle(Color.mib.semantic.error) }
            Button("소파에서 같이 보기") {
                if let selected {
                    session.watch(session.library.videos.first { $0.id == selected.id } ?? selected)
                    dismiss()
                }
            }.buttonStyle(D1PrimaryStyle()).disabled(selected == nil).padding(.horizontal, 22).padding(.top, -4).padding(.bottom, 0)
        }
    }
    private func videoRow(_ video: CouchVideo) -> some View {
        HStack(spacing: 0) {
        Button { selected = video } label: {
            HStack(spacing: 12) {
                AsyncImage(url: video.thumbnailURL) { image in image.resizable().scaledToFill() } placeholder: {
                    ZStack { Color.mib.bg.mintSoft; Image(systemName: "play.rectangle").foregroundStyle(Color.mib.text.secondary) }
                }.frame(width: 108, height: 70).clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(alignment: .bottomTrailing) {
                        if let count = video.videoCount {
                            Text("▶ \(count)").pretendard(.medium, 12).foregroundStyle(.white)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 6)).padding(4)
                        }
                    }
                VStack(alignment: .leading, spacing: 2) {
                    Text(video.title).pretendard(.medium, 14, tracking: -0.7).lineLimit(2)
                    Text(video.videoCount.map { "영상 \($0)개" } ?? (video.source.isPlaylist ? "플레이리스트" : "YouTube 영상"))
                        .pretendard(.regular, 14, tracking: -0.7)
                }
                Spacer(minLength: 0)
                if selected?.id == video.id { D1Icon(name: "check") }
            }.padding(.leading, 10).padding(.trailing, 14).frame(maxWidth: .infinity, alignment: .leading).frame(height: 100)
                .modifier(RepresentativeSelectionSurface(selected: selected?.id == video.id, radius: 18, neutral: .white))
                .environment(\.updatedFlowDesign, false)
                .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(selected?.id == video.id ? Color.rep4.c04 : Color(uiColor: Palette.uiColor("#DDDDDD")), lineWidth: selected?.id == video.id ? 1.5 : 1))
        }.buttonStyle(.plain).accessibilityAddTraits(selected?.id == video.id ? .isSelected : [])
        Button { session.library.toggleFavorite(video) } label: {
            Image(systemName: session.library.favorite(video) ? "heart.fill" : "heart")
                .font(.system(size: 20)).foregroundStyle(session.library.favorite(video) ? FlowDesign.blue : Color.rep4.c29)
                .frame(width: 44, height: 52)
        }.buttonStyle(.plain)
            .accessibilityLabel(session.library.favorite(video) ? "찜 해제" : "찜하기")
            .accessibilityValue(video.title)
        }
    }
    private func addLink() {
        guard let source = YouTubeSource.parse(link) else { linkError = "YouTube 영상 또는 플레이리스트 링크를 확인해 주세요."; return }
        selected = session.library.add(source); link = ""; linkError = nil; tab = 0
        Task { await session.library.resolveTitle(for: source) }
    }
}

/// The source player artwork remains visible while the live video is loading.
/// It never replaces a ready YouTube player or fabricates playback progress.
private struct CouchLoadingArtwork: View {
    let title: String
    let failed: Bool
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                FlowDesign.video
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
                .foregroundStyle(Color.white).clipped()
        }.allowsHitTesting(false)
    }
}

struct CouchCompanionPreview: View {
    let dolls: [DollState]
    var body: some View {
        ZStack(alignment: .bottom) {
            Image("flow_couch_sofa").resizable().scaledToFill()
                .frame(width: 336, height: 139).clipped().offset(x: 4.5)
            CompanionScene(dolls: Array(dolls.prefix(2)), kind: .couch)
                .renderedOnlyWhileVisible(background: .clear).frame(height: 248).offset(y: -3)
        }.frame(height: 252).clipped()
            .accessibilityLabel("선택한 인형이 앉은 소파")
    }
}

struct CouchMiniPlayer: View {
    let session: CouchSession
    let open: () -> Void
    var body: some View {
        YouTubePlayerView(player: session.player)
            .frame(minWidth: 200, minHeight: 200)
            .overlay {
            if !session.player.ready {
                CouchLoadingArtwork(title: session.current?.title ?? "YouTube", failed: session.player.error != nil)
            }
        }.clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.white, lineWidth: 4))
            .accessibilityAction(named: "영상 선택하기", open)
            .contextMenu {
                Button("영상 선택하기", action: open)
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
                            Capsule().fill(FlowDesign.blue).frame(width: 3, height: height)
                        }
                    }.frame(width: 16, height: 16)
                    Text("\(session.player.title.isEmpty ? session.current?.title ?? "YouTube" : session.player.title) · \(FocusSession.clock(session.player.elapsed, hours: false))")
                        .pretendard(.regular, 14, tracking: -0.7).lineLimit(1)
                }.frame(maxWidth: .infinity, alignment: .leading)
            }.accessibilityLabel("영상 선택하기")
            Button { session.player.toggle() } label: {
                D1PlaybackGlyph(paused: !session.player.playing).scaleEffect(0.43)
                    .frame(width: 44, height: 44).background(FlowDesign.selected, in: RoundedRectangle(cornerRadius: 12))
            }.disabled(!session.player.ready).accessibilityLabel(session.player.playing ? "일시정지" : "재생")
            Button { session.stop() } label: {
                Image(systemName: "stop.fill").font(.system(size: 14, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .background(FlowDesign.selected, in: RoundedRectangle(cornerRadius: 12))
            }.accessibilityLabel("그만 보기").accessibilityIdentifier("couch-stop")
        }.buttonStyle(.plain).padding(.leading, 12).padding(.trailing, 4)
            .frame(height: 52).foregroundStyle(Color.mib.text.primary)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 14))
            .contextMenu {
                Button("이전 영상", systemImage: "backward.end.fill") { session.player.previous() }
                    .disabled(session.player.count < 2 || !session.player.ready)
                Button("다음 영상", systemImage: "forward.end.fill") { session.player.next() }
                    .disabled(session.player.count < 2 || !session.player.ready)
                Button("그만 보기", systemImage: "stop.fill") { session.stop() }
            }
    }
}
