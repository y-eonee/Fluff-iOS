import SwiftUI

extension FocusFlowView {
    var selectionScreen: some View {
        ZStack(alignment: .bottom) {
                Color.clear.contentShape(Rectangle()).ignoresSafeArea().onTapGesture { dismiss() }
                VStack(spacing: 0) {
                    Capsule().fill(Color.mib.bg.mintSoft).frame(width: 40, height: 4).padding(.top, 12)
                    Text("함께 집중할 인형 선택").pretendard(.bold, 17).frame(maxWidth: .infinity, alignment: .leading).padding(.top, 20).padding(.bottom, 24)
                    ScrollView {
                        if dolls.isEmpty {
                            VStack(spacing: 16) {
                                Text("함께할 인형이 없어요").pretendard(.bold, 17)
                                Button("인형 만들기") { creating = true }.buttonStyle(D1SecondaryStyle())
                            }
                        } else {
                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                                ForEach(dolls) { doll in dollChoice(doll) }
                            }
                        }
                    }.scrollIndicators(.hidden)
                    Button("함께 시작하기") {
                        guard let selection else { return }
                        session.select(selection); showMain = true
                    }.buttonStyle(D1PrimaryStyle())
                        .disabled(selection == nil || !dolls.contains { $0.id == selection })
                        .padding(.top, 20).padding(.bottom, 32)
                }.padding(.horizontal, 22).frame(height: dolls.count <= 2 ? 334 : 474)
                    .background(FocusStyle.paper, in: UnevenRoundedRectangle(topLeadingRadius: 22, topTrailingRadius: 22))
                    .background(.ultraThinMaterial, in: UnevenRoundedRectangle(topLeadingRadius: 22, topTrailingRadius: 22))
                    .accessibilityAction(.escape) { dismiss() }
        }.ignoresSafeArea(edges: .bottom)
        .background {
            roomBackground.ignoresSafeArea()
        }.fullScreenCover(isPresented: $creating) { CreateFlowView(onExit: { dismiss() }) { doll in selection = doll.id } }
    }

    private func dollChoice(_ doll: Doll) -> some View {
        let chosen = selection == doll.id
        return Button { selection = doll.id } label: {
            VStack(spacing: 4) {
                DollThumbnail(data: doll.imageData, maxPixel: 280).frame(height: 80)
                Text(doll.name).pretendard(.regular, 16)
            }.frame(maxWidth: .infinity).frame(height: 128)
                .background(chosen ? Color.mib.bg.mintSoft : FocusStyle.paper, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.mib.line.selected, lineWidth: chosen ? 2 : 1.4))
                .overlay(alignment: .topTrailing) { if chosen { D1Icon(name: "check").padding(8) } }
                .contentShape(Rectangle())
        }.buttonStyle(.plain).accessibilityLabel(doll.name).accessibilityAddTraits(chosen ? .isSelected : [])
    }

    func main(_ doll: Doll) -> some View {
        VStack(spacing: 0) {
            header { showMain = false }
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    companionPreview(doll)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("오늘 \(doll.name.josa("이랑", "랑")) 할 공부").pretendard(.bold, 17)
                        HStack(spacing: 8) {
                            ForEach(StudyActivity.allCases) { activity in activityCard(activity) }
                        }
                    }
                    VStack(alignment: .leading, spacing: 16) {
                        Text("집중 시간 설정").pretendard(.bold, 17)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("집중 시간").pretendard(.regular, 16)
                            timeStepper(minutes: session.record.focusMinutes, range: 1...180, label: "집중 시간") {
                                session.configure(focus: $0, rest: session.record.restMinutes); session.confirmTime()
                            }
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text("쉬는 시간").pretendard(.regular, 16)
                            timeStepper(minutes: session.record.restMinutes, range: 1...60, label: "쉬는 시간") {
                                session.configure(focus: session.record.focusMinutes, rest: $0); session.confirmTime()
                            }
                        }
                    }
                }.padding(.horizontal, 16).padding(.top, 16).padding(.bottom, 24)
            }.scrollIndicators(.hidden)
            Button("집중 시작하기") { session.start() }.buttonStyle(D1PrimaryStyle())
                .disabled(!session.canStart)
                .padding(.horizontal, 16).padding(.top, 24).padding(.bottom, 16)
        }
    }

    private func companionPreview(_ doll: Doll) -> some View {
        ZStack(alignment: .top) {
            roomBackground
            Group {
                if let configuration = doll.presetConfiguration {
                    PresetDollView(configuration: configuration, cameraDistance: 0.88, cameraTarget: 0.19, fitsModel: true)
                        .renderedOnlyWhileVisible(background: .clear)
                } else { Image(uiImage: doll.image).resizable().scaledToFit() }
            }.frame(width: 128, height: 174).padding(.top, 8)
        }.frame(maxWidth: .infinity).frame(height: 188)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 11).padding(.vertical, 10)
            .background(Color.mib.bg.surface, in: RoundedRectangle(cornerRadius: 22))
    }

    private func activityCard(_ activity: StudyActivity) -> some View {
        let chosen = session.activity == activity
        return Button { session.selectActivity(activity); session.confirmTime() } label: {
            VStack(spacing: 4) {
                D1Icon(name: activity.icon).frame(width: 48, height: 48)
                    .background(Color.mib.bg.mintSoft, in: RoundedRectangle(cornerRadius: 14))
                Text(activity.title).pretendard(.regular, 16)
                Text("추천 \(activity.recommendedMinutes)분").pretendard(.medium, 13).foregroundStyle(FocusStyle.muted)
            }.frame(maxWidth: .infinity).frame(height: 128)
                .background(chosen ? Color.mib.bg.mintSoft : FocusStyle.paper, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(FocusStyle.line))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(chosen ? Color.mib.line.selected : Color.clear, lineWidth: 2))
                .overlay(alignment: .topTrailing) { if chosen { D1Icon(name: "check").padding(8) } }
                .contentShape(Rectangle())
        }.buttonStyle(.plain).accessibilityAddTraits(chosen ? .isSelected : [])
    }

    private func timeStepper(minutes: Int, range: ClosedRange<Int>, label: String, set: @escaping (Int) -> Void) -> some View {
        HStack {
            Button { set(max(range.lowerBound, minutes - 5)); customTime = true } label: { D1Icon(name: "minus").frame(width: 44, height: 44).contentShape(Rectangle()) }
                .disabled(minutes <= range.lowerBound).accessibilityLabel("\(label) 줄이기")
            Button { session.confirmTime() } label: {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(minutes)").pretendard(.bold, 21)
                    Text("분").pretendard(.regular, 16)
                }.frame(maxWidth: .infinity).frame(height: 44)
            }.accessibilityLabel("\(label) \(minutes)분으로 설정")
            Button { set(min(range.upperBound, minutes + 5)); customTime = true } label: { D1Icon(name: "plus").frame(width: 44, height: 44).contentShape(Rectangle()) }
                .disabled(minutes >= range.upperBound).accessibilityLabel("\(label) 늘리기")
        }.buttonStyle(.plain).padding(4).d1Surface(radius: 10)

    }
}
