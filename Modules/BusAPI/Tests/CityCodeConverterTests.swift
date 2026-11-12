@testable import BusAPI
import Testing

struct CityCodeConverterTests {
    /// A slice of TAGO's getCtyCodeList.
    let cities = [
        BusCity(code: 12, name: "세종특별시"),
        BusCity(code: 21, name: "부산광역시"),
        BusCity(code: 24, name: "광주광역시"),
        BusCity(code: 39, name: "제주도"),
        BusCity(code: 31020, name: "성남시"),
        BusCity(code: 31250, name: "광주시"),
    ]

    @Test(arguments: [
        ("성남시", "경기도", "31020"),
        ("광주시", "경기도", "31250"),
        (nil, "광주광역시", "24"),
        ("해운대구", "부산광역시", "21"),
        (nil, "세종특별자치시", "12"),
        ("제주시", "제주특별자치도", "39"),
        ("서울특별시", "서울특별시", "1000"),
    ] as [(String?, String?, String)])
    func findsTagoCityCode(locality: String?, administrativeArea: String?, expected: String) {
        #expect(CityCodeConverter
            .findCode(locality: locality, administrativeArea: administrativeArea, in: cities) == expected)
    }

    @Test
    func unknownPlaceHasNoCode() {
        #expect(CityCodeConverter.findCode(locality: "어딘가", administrativeArea: nil, in: cities) == nil)
    }
}
