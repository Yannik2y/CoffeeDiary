import SwiftUI

struct ShotTypePicker: View {
    @Binding var shotType: ShotType
    
    var body: some View {
        Picker("Shot".localized, selection: $shotType) {
            ForEach(ShotType.allCases) { type in
                Text(type.displayName).tag(type)
            }
        }
        .pickerStyle(.segmented)
        .tint(AppTheme.accentSecondary)
    }
}

struct ShotTypePicker_Previews: PreviewProvider {
    static var previews: some View {
        ShotTypePicker(shotType: .constant(.double))
            .padding()
            .previewLayout(.sizeThatFits)
    }
}


