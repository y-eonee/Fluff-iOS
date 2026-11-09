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
            }.padding(.horizontal, 20).padding(.top, 4).padding(.bottom, 10)
            if session.choosing { picker }
            else { watching }
        }.foregroundStyle(Color.mib.text.primary).background(Color.mib.bg.screen)
            .task { await session.account.restore() }
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
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    accountCard
                    HStack(spacing: 4) {
                        TextField("유튜브 플레이리스트 링크 붙여넣기", text: $link, prompt: Text("유튜브 플레이리스트 링크 붙여넣기").foregroundStyle(Color.mib.text.secondary))
                            .pretendard(.regular, 14).textInputAutocapitalization(.never)
                            .autocorrectionDisabled().keyboardType(.URL).submitLabel(.go).onSubmit(addLink)
                        if !link.isEmpty {
                            Button(action: addLink) { Image(systemName: "plus").frame(width: 44, height: 44) }.accessibilityLabel("링크 추가")
                        }
                    }.padding(.leading, 14).frame(minHeight: 50).d1Surface(radius: 14)
                    if let linkError { Text(linkError).pretendard(.medium, 13).foregroundStyle(Color.mib.semantic.error).frame(maxWidth: .infinity, alignment: .leading) }
                    HStack(spacing: 8) {
                        ForEach(Array(["내 플레이리스트", "최근 본 영상", "같이 보기 좋은"].enumerated()), id: \.offset) { index, title in
                            Button { tab = index } label: {
                                Text(title).pretendard(tab == index ? .bold : .medium, 13).frame(maxWidth: .infinity, minHeight: 44)
                                    .background(tab == index ? Color.mib.bg.mintSoft : Color.mib.bg.surface, in: RoundedRectangle(cornerRadius: 10))
                                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(tab == index ? Color.mib.text.primary : Color.mib.text.secondary, lineWidth: tab == index ? 2 : 1.4))
                            }.buttonStyle(.plain).accessibilityAddTraits(tab == index ? .isSelected : [])
                        }
                    }
                    if candidates.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: tab == 2 ? "heart" : "play.rectangle").font(.system(size: 30))
                            Text(tab == 2 ? "함께 보고 싶은 영상에 하트를 눌러 주세요" : tab == 1 ? "함께 본 영상이 여기에 모여요" : "계정을 연결하거나 유튜브 링크를 추가해 주세요")
                                .pretendard(.medium, 14).multilineTextAlignment(.center)
                        }.foregroundStyle(Color.mib.text.secondary).frame(maxWidth: .infinity).padding(.vertical, 48)
                    }
                    LazyVStack(spacing: 10) {
                        ForEach(candidates) { video in videoRow(video) }
                    }
                }.padding(.horizontal, 16).padding(.bottom, 16)
            }.scrollIndicators(.hidden)
            Button("소파에서 같이 보기") {
                if let selected { session.watch(session.library.videos.first { $0.id == selected.id } ?? selected) }
            }.buttonStyle(D1PrimaryStyle()).disabled(selected == nil).padding(.horizontal, 22).padding(.vertical, 8)
        }
    }
    private var accountCard: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(Color(uiColor: Palette.uiColor("#F25454"))).frame(width: 40, height: 34)
                Image("couch_youtube_play").resizable().scaledToFit().frame(width: 16, height: 16)
            }.accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(session.account.isConnected ? "YouTube 계정 연결됨" : "YouTube 계정 연결").pretendard(.bold, 15)
                Text(session.account.isLoading ? "플레이리스트를 불러오고 있어요" : session.account.isConnected ? "내 플레이리스트 \(session.account.playlists.count)개를 불러왔어요" : "내 플레이리스트를 함께 볼 수 있어요")
                    .pretendard(.medium, 12).foregroundStyle(Color.mib.text.secondary)
            }
            Spacer(minLength: 0)
            if session.account.isLoading { ProgressView() }
            else {
                Button(session.account.isConnected ? "변경" : "연결") {
                    if session.account.isConnected { accountActions = true }
                    else { Task { await session.account.connect() } }
                }.pretendard(.medium, 13).frame(minWidth: 44, minHeight: 44)
            }
        }.padding(.horizontal, 14).frame(minHeight: 74).d1Surface(radius: 14)
    }
    private func videoRow(_ video: CouchVideo) -> some View {
        Button { selected = video } label: {
            HStack(spacing: 12) {
                AsyncImage(url: video.thumbnailURL) { image in image.resizable().scaledToFill() } placeholder: {
                    ZStack { Color.mib.bg.mintSoft; Image(systemName: "play.rectangle").foregroundStyle(Color.mib.text.secondary) }
                }.frame(width: 96, height: 54).clipShape(RoundedRectangle(cornerRadius: 8))
                VStack(alignment: .leading, spacing: 5) {
                    Text(video.title).pretendard(.bold, 15).lineLimit(2)
                    Text(video.videoCount.map { "영상 \($0)개" } ?? (video.source.isPlaylist ? "플레이리스트" : "YouTube 영상"))
                        .pretendard(.medium, 13).foregroundStyle(Color.mib.text.secondary)
                }
                Spacer(minLength: 0)
                if selected?.id == video.id { D1Icon(name: "check") }
            }.padding(10).frame(maxWidth: .infinity, alignment: .leading)
                .background(selected?.id == video.id ? Color.mib.bg.mintSoft : Color.mib.bg.surface, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(selected?.id == video.id ? Color.mib.line.selected : Color.mib.line.default, lineWidth: selected?.id == video.id ? 2 : 1))
        }.buttonStyle(.plain).accessibilityAddTraits(selected?.id == video.id ? .isSelected : [])
    }
    private func addLink() {
        guard let source = YouTubeSource.parse(link) else { linkError = "YouTube 영상 또는 플레이리스트 링크를 확인해 주세요."; return }
        selected = session.library.add(source); link = ""; linkError = nil; tab = 0
        Task { await session.library.resolveTitle(for: source) }
    }
    private var watching: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 12) {
                    YouTubePlayerView(player: session.player).frame(height: 201).clipShape(RoundedRectangle(cornerRadius: 14))
                    CouchCompanionPreview(dolls: session.dolls)
                    nowPlaying
                    if let error = session.player.error {
                        VStack(spacing: 8) {
                            Text(error).pretendard(.medium, 13)
                            HStack {
                                Button("다시 시도") { if let source = session.current?.source { session.player.load(source) } }
                                Spacer()
                                Button("YouTube에서 열기") { if let url = session.current?.source.url { session.player.pause(); openURL(url) } }
                            }.pretendard(.bold, 14).frame(minHeight: 44)
                        }.padding(16).d1Surface(radius: 14)
                    }
                }.padding(.horizontal, 16).padding(.bottom, 12)
            }.scrollIndicators(.hidden)
            Button("홈에서 계속 보기") { dismiss() }.buttonStyle(D1SecondaryStyle()).padding(.horizontal, 22).padding(.vertical, 8)
        }
    }
    private var nowPlaying: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(session.player.count > 0 ? "같이 보는 중 · \(session.player.index + 1) / \(session.player.count)" : "같이 보는 중")
                    .pretendard(.medium, 13).foregroundStyle(Color.mib.text.secondary)
                Spacer()
                if let video = session.current {
                    Button { session.library.toggleFavorite(video) } label: {
                        Image(systemName: session.library.favorite(video) ? "heart.fill" : "heart").foregroundStyle(Color.mib.action.primary).frame(width: 44, height: 20).contentShape(Rectangle()).padding(.vertical, 12)
                    }.frame(height: 20).accessibilityLabel(session.library.favorite(video) ? "좋아요 취소" : "같이 보기 좋은 영상에 추가")
                }
            }
            Text(session.player.title.isEmpty ? session.current?.title ?? "YouTube" : session.player.title).pretendard(.bold, 20).lineLimit(1)
            Text(session.player.ready ? "\(time(session.player.elapsed)) / \(time(session.player.duration))" : "영상을 준비하고 있어요")
                .pretendard(.medium, 13).foregroundStyle(Color.mib.text.secondary)
            ProgressView(value: min(max(session.player.elapsed, 0), max(session.player.duration, 1)), total: max(session.player.duration, 1)).tint(Color.mib.action.primary)
            HStack(spacing: 22) {
                Spacer()
                Button { session.player.previous() } label: { Image("couch_next").resizable().frame(width: 24, height: 24).rotationEffect(.degrees(180)).frame(width: 44, height: 44) }
                    .disabled(session.player.count < 2 || !session.player.ready).accessibilityLabel("이전 영상")
                Button { session.player.toggle() } label: { Image(systemName: session.player.playing ? "pause.fill" : "play.fill").font(.system(size: 25)).frame(width: 64, height: 64).foregroundStyle(Color.mib.text.onPrimary).background(Color.mib.action.primary, in: Circle()) }
                    .disabled(!session.player.ready).accessibilityLabel(session.player.playing ? "일시정지" : "재생")
                Button { session.player.next() } label: { Image("couch_next").resizable().frame(width: 24, height: 24).frame(width: 44, height: 44) }
                    .disabled(session.player.count < 2 || !session.player.ready).accessibilityLabel("다음 영상")
                Spacer()
            }
            HStack(spacing: 10) {
                Button("플리 바꾸기") { session.player.pause(); selected = session.current; session.choosing = true }.frame(maxWidth: .infinity, minHeight: 44).d1Surface(radius: 10)
                Button("그만 보기") { session.stop(); dismiss() }.frame(maxWidth: .infinity, minHeight: 44).d1Surface(radius: 10)
            }.pretendard(.medium, 14)
        }.padding(.horizontal, 22).padding(.vertical, 14).d1Surface(radius: 14)
    }
    private func time(_ value: Double) -> String { let seconds = Int(max(0, value)); return String(format: "%d:%02d", seconds / 60, seconds % 60) }
}

struct CouchCompanionPreview: View {
    let dolls: [DollState]
    var body: some View {
        ZStack {
            Image("couch_backdrop").resizable().scaledToFill()
            CompanionScene(dolls: Array(dolls.prefix(2)), kind: .couch).renderedOnlyWhileVisible(background: .clear)
        }.frame(height: 150).clipped().clipShape(RoundedRectangle(cornerRadius: 14))
            .accessibilityLabel("인형들과 함께 앉은 소파")
    }
}

struct CouchMiniPlayer: View {
    let session: CouchSession
    let open: () -> Void
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                Button(action: open) {
                    HStack { Image(systemName: "arrow.up.left.and.arrow.down.right"); Text(session.player.title.isEmpty ? "소파에서 같이 보는 중" : session.player.title).lineLimit(1) }
                }.frame(maxWidth: .infinity, alignment: .leading)
                Button { session.player.toggle() } label: { Image(systemName: session.player.playing ? "pause.fill" : "play.fill").frame(width: 44, height: 44) }.disabled(!session.player.ready).accessibilityLabel(session.player.playing ? "일시정지" : "재생")
                Button { session.stop() } label: { Image(systemName: "xmark").frame(width: 44, height: 44) }.accessibilityLabel("그만 보기")
            }.pretendard(.medium, 13).padding(.leading, 12)
            // YouTube embeds require at least a 200 × 200 viewport, including in the room.
            YouTubePlayerView(player: session.player).frame(height: 200)
            if session.player.error != nil { Button("재생 문제 확인하기", action: open).pretendard(.medium, 13).frame(height: 44) }
        }.background(Color.mib.bg.surface).clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.mib.line.default))
            .foregroundStyle(Color.mib.text.primary)
    }
}
