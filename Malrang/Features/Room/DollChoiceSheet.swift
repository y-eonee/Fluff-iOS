import SwiftUI

struct DollChoiceSheet: View {
  let dolls: [Doll]
  let multiple: Bool
  var title: String? = nil
  var subtitle: String? = nil
  var actionTitle: String? = nil
  var maximumSelection: Int? = nil
  var sourceLayout = false
  let onChoose: ([Doll]) -> Void
  @State private var selection: Set<UUID> = []
  @Environment(\.dismiss) private var dismiss
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Capsule().fill(Color.mib.line.default).frame(width: 40, height: 4).frame(maxWidth: .infinity)
        .padding(.top, 12)
      Text(title ?? (multiple ? "같이 구경할 인형" : "누구를 재울까요?")).pretendard(.bold, 17)
        .frame(height: sourceLayout ? 25 : nil).padding(.top, sourceLayout ? 24 : 18)
      Text(subtitle ?? (multiple ? "여러 명을 같이 골라도 돼요" : "한 번에 한 인형만 재울 수 있어요"))
        .pretendard(.medium, 13).frame(height: sourceLayout ? 19 : nil).padding(.top, 8)
      ScrollView {
        LazyVGrid(
          columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible())], spacing: 12
        ) {
          ForEach(dolls) { doll in
            Button {
              if multiple {
                if selection.contains(doll.id) {
                  selection.remove(doll.id)
                } else if selection.count < (maximumSelection ?? Int.max) {
                  selection.insert(doll.id)
                }
              } else {
                selection = [doll.id]
              }
            } label: {
              VStack(spacing: 4) {
                DollThumbnail(data: doll.imageData).frame(height: 80)
                Text(doll.name).pretendard(.regular, 16).lineLimit(1)
              }.frame(maxWidth: .infinity).frame(height: 128)
                .modifier(RepresentativeSelectionSurface(selected: selection.contains(doll.id), radius: 14, neutral: Color.rep4.c11))
                .overlay(alignment: .topTrailing) {
                  if selection.contains(doll.id) { D1Icon(name: "check").padding(8) }
                }
            }.buttonStyle(.plain)
              .disabled(multiple && !selection.contains(doll.id) && selection.count >= (maximumSelection ?? Int.max))
              .opacity(multiple && !selection.contains(doll.id) && selection.count >= (maximumSelection ?? Int.max) ? 0.5 : 1)
              .accessibilityAddTraits(
              selection.contains(doll.id) ? .isSelected : [])
          }
        }.padding(.vertical, sourceLayout ? 12 : 16)
      }
      Button(actionTitle ?? (multiple ? "같이 구경하기 (\(selection.count))" : "재우기")) {
        onChoose(dolls.filter { selection.contains($0.id) })
        dismiss()
      }.buttonStyle(D1PrimaryStyle()).disabled(selection.isEmpty)
        .padding(.top, sourceLayout ? 13 : 0).padding(.bottom, sourceLayout ? 32 : 16)
    }.padding(.horizontal, 22).background(Color.mib.bg.surface).foregroundStyle(
      Color.mib.text.primary
    )
    .environment(\.updatedFlowDesign, sourceLayout)
    .presentationDetents([.height(489), .large]).presentationDragIndicator(.hidden)
      .presentationCornerRadius(22)
    .onAppear { if let first = dolls.first { selection = [first.id] } }
  }
}

/// The couch source has a full-width sheet, independent of the OS sheet margins.
struct CouchChoicePresentation<Content: View>: View {
  @Environment(\.dismiss) private var dismiss
  @ViewBuilder let content: Content

  var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .bottom) {
        Color.black.opacity(0.12).ignoresSafeArea().onTapGesture { dismiss() }
        content.frame(height: min(489, geometry.size.height + geometry.safeAreaInsets.bottom))
          .background(Color.mib.bg.surface)
          .clipShape(UnevenRoundedRectangle(topLeadingRadius: 22, topTrailingRadius: 22))
          .simultaneousGesture(DragGesture(minimumDistance: 25).onEnded { value in
            if value.startLocation.y < 100 && value.translation.height > 60 { dismiss() }
          })
          .accessibilityAction(.escape) { dismiss() }
      }.frame(width: geometry.size.width, height: geometry.size.height + geometry.safeAreaInsets.bottom)
    }
  }
}
