import CommonCrypto
import Foundation

/// AES-CMAC (RFC 4493).
enum CMAC {
    static func aes(_ message: Data, key: Data) -> Data {
        let k1 = subkey(encrypt([UInt8](repeating: 0, count: 16), key: key))
        let k2 = subkey(k1)
        let bytes = [UInt8](message)
        let blocks = max((bytes.count + 15) / 16, 1)
        let complete = !bytes.isEmpty && bytes.count % 16 == 0
        var last = Array(bytes[((blocks - 1) * 16)...])
        if complete {
            last = zip(last, k1).map { $0 ^ $1 }
        } else {
            last.append(0x80)
            last += [UInt8](repeating: 0, count: 16 - last.count)
            last = zip(last, k2).map { $0 ^ $1 }
        }
        var x = [UInt8](repeating: 0, count: 16)
        for block in 0..<(blocks - 1) {
            x = encrypt(zip(x, bytes[(block * 16)..<(block * 16 + 16)]).map { $0 ^ $1 }, key: key)
        }
        return Data(encrypt(zip(x, last).map { $0 ^ $1 }, key: key))
    }

    private static func subkey(_ block: [UInt8]) -> [UInt8] {
        var shifted = [UInt8](repeating: 0, count: 16)
        var carry: UInt8 = 0
        for index in (0..<16).reversed() {
            shifted[index] = block[index] << 1 | carry
            carry = block[index] >> 7
        }
        if block[0] & 0x80 != 0 { shifted[15] ^= 0x87 }
        return shifted
    }

    private static func encrypt(_ block: [UInt8], key: Data) -> [UInt8] {
        var output = [UInt8](repeating: 0, count: 32)
        var moved = 0
        key.withUnsafeBytes { keyBytes in
            _ = CCCrypt(CCOperation(kCCEncrypt), CCAlgorithm(kCCAlgorithmAES), CCOptions(kCCOptionECBMode),
                        keyBytes.baseAddress, key.count, nil, block, 16, &output, output.count, &moved)
        }
        return Array(output.prefix(16))
    }
}
