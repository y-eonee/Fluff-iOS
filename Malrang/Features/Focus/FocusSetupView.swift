import SwiftUI

extension FocusFlowView {
    var selectionScreen: some View {
        ZStack(alignment: .bottom) {
                Color.mib.text.primary.opacity(0.28).ignoresSafeArea().onTapGesture { dismiss() }
                VStack(spacing: 0) {
                    Capsule().fill(Color.mib.bg.mintSoft).frame(width: 40, height: 4).padding(.top, 12)
                    Text("솜뭉치랑 집중하기").pretendard(.bold, 21).padding(.top, 20).padding(.bottom, 24)
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
                }.padding(.horizontal, 22).frame(height: 489)
                    .background(FocusStyle.paper.opacity(0.85), in: UnevenRoundedRectangle(topLeadingRadius: 22, topTrailingRadius: 22))
                    .background(.ultraThinMaterial, in: UnevenRoundedRectangle(topLeadingRadius: 22, topTrailingRadius: 22))
                    .accessibilityAction(.escape) { dismiss() }
        }.ignoresSafeArea(edges: .bottom)
        .background {
            GeometryReader { geometry in
                Group {
                    if let roomSnapshot { Image(uiImage: roomSnapshot).resizable() }
                    else { Image("focus_room").resizable() }
                }.scaledToFill().frame(width: geometry.size.width, height: geometry.size.height).clipped()
            }.ignoresSafeArea().accessibilityHidden(true)
        }.fullScreenCover(isPresented: $creating) { CreateFlowView { doll in selection = doll.id } }
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
                VStack(alignment: .leading, spacing: 16) {
                    companionPreview(doll).padding(.horizontal, -6)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("오늘 \(doll.name)랑 할 공부").pretendard(.bold, 17)
                        HStack(spacing: 10) {
                            ForEach(StudyActivity.allCases) { activity in activityCard(activity) }
                        }
                    }
                }.padding(.horizontal, 22).padding(.top, 28).padding(.bottom, 20)
            }.scrollIndicators(.hidden)
            Button("집중 시간 설정") { customTime = false; showingSettings = true }
                .buttonStyle(FocusCompactButton()).padding(.horizontal, 22).padding(.bottom, 24)
            Button("집중 시작하기") { session.start() }.buttonStyle(D1PrimaryStyle())
                .padding(.horizontal, 22).padding(.bottom, 16)
        }
    }

    private func companionPreview(_ doll: Doll) -> some View {
        VStack(spacing: 4) {
            Text("\(doll.name)와 총 함께한 시간").pretendard(.medium, 13).foregroundStyle(FocusStyle.muted)
            Text(FocusSession.summary(session.total(with: doll.id))).pretendard(.bold, 28)
            D1Bubble(text: "우리 열심히 해보자!").frame(maxWidth: 242).padding(.top, 8)
            Group {
                if let configuration = doll.presetConfiguration {
                    PresetDollView(configuration: configuration, cameraDistance: 0.88, cameraTarget: 0.19)
                        .renderedOnlyWhileVisible(background: .clear)
                } else { Image(uiImage: doll.image).resizable().scaledToFit() }
            }.frame(height: 200)
        }.padding(.top, 14).frame(maxWidth: .infinity).frame(height: 328, alignment: .top)
            .background(alignment: .bottom) { Image("d1_focus_starburst").resizable().scaledToFit().frame(height: 261).accessibilityHidden(true) }
            .background(CreationStyle.yellow, in: RoundedRectangle(cornerRadius: 14)).clipped()
            .padding(11).background(CreationStyle.blue, in: RoundedRectangle(cornerRadius: 22))
    }

    private func activityCard(_ activity: StudyActivity) -> some View {
        let chosen = session.activity == activity
        return Button { session.selectActivity(activity) } label: {
            VStack(spacing: 4) {
                D1Icon(name: activity.icon).frame(width: 48, height: 48)
                    .background(Color.mib.bg.mintSoft, in: RoundedRectangle(cornerRadius: 14))
                Text(activity.title).pretendard(.bold, 14)
                Text("추천 \(activity.recommendedMinutes)분").pretendard(.medium, 13).foregroundStyle(FocusStyle.muted)
            }.frame(maxWidth: .infinity).frame(height: 128)
                .background(chosen ? Color.mib.bg.mintSoft : FocusStyle.paper, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(FocusStyle.line))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(chosen ? Color.mib.line.selected : Color.clear, lineWidth: 2))
                .overlay(alignment: .topTrailing) { if chosen { D1Icon(name: "check").padding(8) } }
                .contentShape(Rectangle())
        }.buttonStyle(.plain).accessibilityAddTraits(chosen ? .isSelected : [])
    }

    func settingsSummary(_ doll: Doll) -> some View {
        VStack(spacing: 16) {
            header { showingSettings = false }
            VStack(spacing: 8) {
                Text("오늘 함께한 시간").pretendard(.medium, 13)
                Text(FocusSession.summary(session.today())).pretendard(.bold, 28)
                HStack {
                    ForEach(0..<7) { index in
                        let calendar = Calendar(identifier: .iso8601)
                        let start = calendar.dateInterval(of: .weekOfYear, for: .now)!.start
                        let date = calendar.date(byAdding: .day, value: index, to: start)!
                        VStack(spacing: 8) {
                            Text(["월", "화", "수", "목", "금", "토", "일"][index]).pretendard(.medium, 13)
                            Circle().fill(session.minutes(on: date) > 0 ? FocusStyle.sage : FocusStyle.line).frame(width: 6, height: 6)
                        }.frame(maxWidth: .infinity)
                    }
                }
            }.frame(maxWidth: .infinity).frame(height: 167).d1Surface(radius: 14)
            ZStack(alignment: .top) {
                Image("focus_room").resizable().scaledToFill().frame(height: 312).clipped()
                D1Bubble(text: "오늘도 너랑 함께할래.").frame(width: 242).padding(.top, 20)
                if let configuration = doll.presetConfiguration {
                    PresetDollView(configuration: configuration, cameraDistance: 0.88, cameraTarget: 0.19)
                        .frame(width: 220, height: 232).padding(.top, 80).renderedOnlyWhileVisible(background: .clear)
                }
            }.frame(height: 312).clipShape(RoundedRectangle(cornerRadius: 22))
            HStack(spacing: 12) {
                D1Icon(name: session.activity.icon)
                VStack(alignment: .leading, spacing: 4) {
                    Text("오늘은 \(doll.name)랑 \(session.activity.ongoing)해요").pretendard(.medium, 13)
                    Text("집중 \(session.record.focusMinutes)분 · 끝나면 공부 기록에 남아요").pretendard(.medium, 13).foregroundStyle(FocusStyle.muted)
                }
            }.padding(12).frame(maxWidth: .infinity, alignment: .leading).d1Surface()
            Spacer(minLength: 0)
        }.padding(.horizontal, 24)
    }

    var settingsSheet: some View {
        VStack(spacing: 16) {
            Text("집중 시간 설정").pretendard(.bold, 21).padding(.top, 12)
            Text("집중 시간").pretendard(.bold, 14)
            timeStepper(minutes: session.record.focusMinutes, range: 1...180, label: "집중 시간") { session.configure(focus: $0, rest: session.record.restMinutes) }
            Text("쉬는 시간").pretendard(.bold, 14)
            if customTime {
                timeStepper(minutes: session.record.restMinutes, range: 1...60, label: "쉬는 시간") { session.configure(focus: session.record.focusMinutes, rest: $0) }
            } else {
                Text("\(session.record.focusMinutes)분 집중 후 · \(session.record.restMinutes)분 휴식")
                    .pretendard(.regular, 16).frame(maxWidth: .infinity).frame(height: 44).d1Surface(radius: 10)
            }
            HStack(spacing: 10) {
                D1Choice(title: "25 / 5", selected: !customTime && session.record.focusMinutes == 25 && session.record.restMinutes == 5, fillsWidth: true) { customTime = false; session.configure(focus: 25, rest: 5) }.frame(maxWidth: .infinity)
                D1Choice(title: "50 / 10", selected: !customTime && session.record.focusMinutes == 50 && session.record.restMinutes == 10, fillsWidth: true) { customTime = false; session.configure(focus: 50, rest: 10) }.frame(maxWidth: .infinity)
                D1Choice(title: "직접 설정", selected: customTime, fillsWidth: true) { customTime = true }.frame(maxWidth: .infinity)
            }
            Button("함께 시작하기") { showingSettings = false; session.start() }.buttonStyle(D1PrimaryStyle())
            Spacer(minLength: 0)
        }.padding(.horizontal, 22).padding(.top, 12).foregroundStyle(FocusStyle.ink)
            .presentationDetents([.height(489)]).presentationDragIndicator(.visible)
            .presentationCornerRadius(22).presentationBackground(FocusStyle.paper)
    }

    private func timeStepper(minutes: Int, range: ClosedRange<Int>, label: String, set: @escaping (Int) -> Void) -> some View {
        HStack {
            Button { set(max(range.lowerBound, minutes - 5)); customTime = true } label: { D1Icon(name: "minus").frame(width: 44, height: 44).contentShape(Rectangle()) }
                .disabled(minutes <= range.lowerBound).accessibilityLabel("\(label) 줄이기")
            Text("\(minutes)분").pretendard(.bold, 21).frame(maxWidth: .infinity)
            Button { set(min(range.upperBound, minutes + 5)); customTime = true } label: { D1Icon(name: "plus").frame(width: 44, height: 44).contentShape(Rectangle()) }
                .disabled(minutes >= range.upperBound).accessibilityLabel("\(label) 늘리기")
        }.buttonStyle(.plain).padding(4).d1Surface(radius: 10)
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.mib.line.selected, lineWidth: 1.4))
    }
}
