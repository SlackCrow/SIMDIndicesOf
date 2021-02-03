extension String {
    // A simple simd.h based string search function
    // GROSSLY UNTESTED
    func simdIndicesOf(substring: String) -> Array<Int>{
        var toReturn = Array<Int>()
        var inputToUse = self
        // lousy hack that was needed as we don't know the length of the string beforehand
        while(Int(Float(inputToUse.count).truncatingRemainder(dividingBy: 16.0)) != 0){
            inputToUse = inputToUse + " "
        }
        var inputInInteger = Array(inputToUse.utf8)
        let substringInInteger = Array(substring.utf8)
        for _ in 1..<substring.count{
            inputInInteger.append(32)
        }
        let F = SIMD16<UInt8>(repeating: UInt8 (substringInInteger[0]))
        let L = SIMD16<UInt8>(repeating: UInt8(substringInInteger[substring.count-1]))
        let False = SIMDMask<SIMD16<Int8>>(repeating: false)
        for i in 1..<((inputToUse.count - 1 + 16) / 16)+1 {
            let A = SIMD16<UInt8>(inputInInteger[16 * (i-1)...(16 * i) - 1])
            let B = SIMD16<UInt8>(inputInInteger[(16 * (i-1))+(substring.count-1)...((16 * i) - 1)+(substring.count-1)])
            let AF = A .== F
            let BL = B .== L
            let maskResult = AF .& BL
            if((maskResult) != False){
                for j in 0..<16{
                    if(maskResult[j] == true){
                        toReturn.append((i-1)*16+j)
                    }
                }
            }
        }
        
        return toReturn
    }
        func simdIndicesOfIntel(substring: String) -> Array<Int>{
        var toReturn = Array<Int>()
        var inputToUse = self
        // lousy hack that pads the input until it is divisible by 32(or 16 if 128bit).
        while(Int(Float(inputToUse.count).truncatingRemainder(dividingBy: 32.0)) != 0){
            inputToUse = inputToUse + " "
        }
        var inputInInteger = Array(inputToUse.utf8)
        let substringInInteger = Array(substring.utf8)
        for _ in 1..<substring.count{
            inputInInteger.append(32)
        }
        let firstLetterOfSubstring = unsafeBitCast(SIMD32<UInt8>(repeating: UInt8 (substringInInteger[0])), to: __m256i.self)
        let secondLetterOfSubstring = unsafeBitCast(SIMD32<UInt8>(repeating: UInt8(substringInInteger[substring.count-1])), to: __m256i.self)
        for i in 1..<((inputToUse.count - 1 + 32) / 32)+1 {
            let firstPartToCheck = unsafeBitCast(SIMD32<UInt8>(inputInInteger[32 * (i-1)...(32 * i) - 1]), to: __m256i.self)
            let secondPartToCheck = unsafeBitCast(SIMD32<UInt8>(inputInInteger[(32 * (i-1))+(substring.count-1)...((32 * i) - 1)+(substring.count-1)]), to: __m256i.self)
            let FF = _mm256_cmpeq_epi8(firstPartToCheck, firstLetterOfSubstring)
            let SE = _mm256_cmpeq_epi8(secondPartToCheck, secondLetterOfSubstring)
            let andResult = _mm256_and_si256(FF, SE)
            let maskResult = _mm256_movemask_epi8(andResult)
            if(maskResult != 0)
            {
                let andResultConverted = unsafeBitCast(andResult, to: SIMD32<Int8>.self)
                for j in 0..<32{
                    if(andResultConverted[j] == -1){
                        toReturn.append((i-1)*32+j)
                    }
                }
            }
        }
        
        return toReturn
    }

}
