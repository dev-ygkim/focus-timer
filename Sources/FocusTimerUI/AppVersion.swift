// 버전을 올릴 때는 Resources/Info.plist의 CFBundleShortVersionString도 같은 값으로 바꿉니다.
// TDDTests/app-version.sh가 두 값이 같은지 검사합니다.
enum AppVersion {
    static let current = "1.0.0"
}
