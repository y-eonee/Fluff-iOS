import Foundation

extension String {
    /// 받침 여부에 맞는 조사를 붙인다. "귀염둥이".josa("이", "가") → "귀염둥이가"
    func josa(_ afterFinal: String, _ afterVowel: String) -> String {
        guard let last = unicodeScalars.last, (0xAC00...0xD7A3).contains(last.value) else {
            return self + afterVowel
        }
        return self + ((last.value - 0xAC00) % 28 == 0 ? afterVowel : afterFinal)
    }
}
