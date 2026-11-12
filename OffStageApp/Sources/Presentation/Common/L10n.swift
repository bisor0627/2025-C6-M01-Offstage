import SwiftUI

// 화면 문구 키 모음입니다.
// L10n(현지화) 및 A11y(접근성) 문자열을 관리합니다.
// 문구 원본은 OffStageApp/Resources/Localizable.xcstrings 입니다. 키를 추가하면 여기에도 직접 추가합니다.

enum L10n {
    private static func key(_ key: String) -> LocalizedStringKey {
        LocalizedStringKey(key)
    }

    enum Bus {
        enum Arrival {
            /// "현재 운행중인 버스 위치:"
            static var currentBusLocation: LocalizedStringKey {
                key("bus.arrival.currentBusLocation")
            }

            /// "도착 예정"
            static var imminent: LocalizedStringKey {
                key("bus.arrival.imminent")
            }

            /// "도착 예정 정보 없음"
            static var noInformation: LocalizedStringKey {
                key("bus.arrival.noInformation")
            }

            /// "현재는 운행중인 노선이 없습니다."
            static var noOperatingRoutes: LocalizedStringKey {
                key("bus.arrival.noOperatingRoutes")
            }

            enum Error {
                /// "도착 정보를 불러오는 데 실패했습니다: %@"
                static var loadFailed: LocalizedStringKey {
                    key("bus.arrival.error.loadFailed")
                }
            }
        }
    }

    enum BusVision {
        enum Detection {
            /// "번이 맞나요?"
            static var confirmBusNumber: LocalizedStringKey {
                key("busVision.detection.confirmBusNumber")
            }

            /// "타려는 버스 번호가\\n"
            static var confirmBusNumberPrefix: LocalizedStringKey {
                key("busVision.detection.confirmBusNumberPrefix")
            }

            /// "버스 인식 중"
            static var inProgress: LocalizedStringKey {
                key("busVision.detection.inProgress")
            }

            /// "아니요, 다시 인식할게요"
            static var retry: LocalizedStringKey {
                key("busVision.detection.retry")
            }

            /// "아니요, 목록에서 고를게요"
            static var selectFromList: LocalizedStringKey {
                key("busVision.detection.selectFromList")
            }

            /// "다른 번호의 버스입니다."
            static var wrongBusNumber: LocalizedStringKey {
                key("busVision.detection.wrongBusNumber")
            }
        }

        enum Debug {
            /// "%@번 탐지중" (문맥: 버스비전: 디버그 탐지 상태)
            static var detectingWithNumber: LocalizedStringKey {
                key("busVision.debug.detectingWithNumber")
            }
        }
    }

    enum Common {
        enum Confirmation {
            /// "아니오"
            static var no: LocalizedStringKey {
                key("common.confirmation.no")
            }

            /// "네, 맞아요."
            static var yes: LocalizedStringKey {
                key("common.confirmation.yes")
            }

            /// "예"
            static var yesShort: LocalizedStringKey {
                key("common.confirmation.yesShort")
            }
        }

        enum Ui {
            /// "취소" (문맥: 공용: 취소 버튼)
            static var buttonCancel: LocalizedStringKey {
                key("common.ui.button.cancel")
            }

            /// "다음" (문맥: 공용: 다음 버튼)
            static var buttonNext: LocalizedStringKey {
                key("common.ui.button.next")
            }

            /// "이전" (문맥: 공용: 이전 버튼)
            static var buttonPrevious: LocalizedStringKey {
                key("common.ui.button.previous")
            }

            /// "다시 시도" (문맥: 공용: 재시도 버튼)
            static var buttonRetry: LocalizedStringKey {
                key("common.ui.button.retry")
            }

            /// "저장" (문맥: 공용: 저장 버튼)
            static var buttonSave: LocalizedStringKey {
                key("common.ui.button.save")
            }

            /// " 입니다."
            static var suffixIs: LocalizedStringKey {
                key("common.ui.suffix.is")
            }

            /// "알 수 없는 위치" (문맥: 공용: 위치 정보 미확인 시 표시)
            static var unknownLocation: LocalizedStringKey {
                key("common.ui.unknownLocation")
            }
        }
    }

    enum Debug {
        enum Ui {
            /// "Api Test View" (문맥: 디버그: Api 테스트 뷰 이동 버튼)
            static var buttonApiTest: LocalizedStringKey {
                key("debug.ui.button.apiTest")
            }

            /// "Clear" (문맥: 디버그: 로그 지우기 버튼)
            static var buttonClear: LocalizedStringKey {
                key("debug.ui.button.clear")
            }

            /// "STT & TTS Test View" (문맥: 디버그: STT/TTS 테스트 뷰 이동 버튼)
            static var buttonSttTtsTest: LocalizedStringKey {
                key("debug.ui.button.sttTtsTest")
            }

            /// "207, 306" (문맥: 디버그: 버스 비전 테스트 링크)
            static var linkBusVision: LocalizedStringKey {
                key("debug.ui.link.busVision")
            }

            /// "Debug" (문맥: 디버그: 화면 타이틀)
            static var title: LocalizedStringKey {
                key("debug.ui.title")
            }

            /// "API Flow" (문맥: 디버그: MVP 테스트 내비게이션 타이틀)
            static var titleApiFlow: LocalizedStringKey {
                key("debug.ui.title.apiFlow")
            }

            /// "L10n Test" (문맥: 디버그: L10n 테스트 화면 타이틀)
            static var titleL10nTest: LocalizedStringKey {
                key("debug.ui.title.l10nTest")
            }

            /// "Switch to English" (문맥: 디버그: 언어 전환 토글 레이블)
            static var toggleSwitchToEnglish: LocalizedStringKey {
                key("debug.ui.toggle.switchToEnglish")
            }
        }

        enum Mvp {
            /// "예: 441" (문맥: 디버그: 노선 입력 예시)
            static var placeholderRouteExample: LocalizedStringKey {
                key("debug.mvp.placeholder.routeExample")
            }

            /// "**%@** 정류장을 통과하는 버스 번호를 입력하세요." (문맥: 디버그: 노선 입력 안내)
            static var promptEnterRouteForStop: LocalizedStringKey {
                key("debug.mvp.prompt.enterRouteForStop")
            }
        }
    }

    enum Home {
        enum Button {
            /// "버스 찾기"
            static var findBus: LocalizedStringKey {
                key("home.button.findBus")
            }

            /// "주변 정류장 찾기"
            static var findNearbyStops: LocalizedStringKey {
                key("home.button.findNearbyStops")
            }
        }

        enum Map {
            /// "%@ 인근"
            static var near: LocalizedStringKey {
                key("home.map.near")
            }

            /// "주변 탐색된 정류장이\\n없습니다."
            static var noStopsFound: LocalizedStringKey {
                key("home.map.noStopsFound")
            }

            /// "주변에 정류장이 없습니다."
            static var noStopsFoundSimple: LocalizedStringKey {
                key("home.map.noStopsFound.simple")
            }

            /// "버스 정보를 불러오지 못했습니다.\n잠시 후 다시 시도해 주세요."
            static var loadFailed: LocalizedStringKey {
                key("home.map.loadFailed")
            }

            /// "오늘은 조회가 많아 버스 정보를\n불러올 수 없습니다. 내일 다시 시도해 주세요."
            static var dailyLimit: LocalizedStringKey {
                key("home.map.dailyLimit")
            }
        }

        enum Sheet {
            /// "버스가 두번째 전 정류장에서 출발하면\\n버스 인식을 시작할 수 있어요."
            static var busDetectionGuide: LocalizedStringKey {
                key("home.sheet.busDetectionGuide")
            }

            /// "목록에 없어요."
            static var notFound: LocalizedStringKey {
                key("home.sheet.notFound")
            }

            /// "노선 번호를 선택하세요."
            static var selectBusRoute: LocalizedStringKey {
                key("home.sheet.selectBusRoute")
            }

            /// "버스 인식하기"
            static var startBusDetection: LocalizedStringKey {
                key("home.sheet.startBusDetection")
            }
        }

        enum Stt {
            /// "몇 번 버스를\\n탑승하시나요?"
            static var askBusNumber: LocalizedStringKey {
                key("home.stt.askBusNumber")
            }

            /// "몇번 버스를 탑승하시나요?"
            static var askBusNumberSimple: LocalizedStringKey {
                key("home.stt.askBusNumberSimple")
            }

            /// "가장 가까운 정류장은 **%@** 입니다. 맞습니까?"
            static var confirmNearestStop: LocalizedStringKey {
                key("home.stt.confirmNearestStop")
            }

            /// "현재 주변 정류장은\\n"
            static var currentNearbyStopPrefix: LocalizedStringKey {
                key("home.stt.currentNearbyStopPrefix")
            }

            /// "번호를 듣는중이에요."
            static var listening: LocalizedStringKey {
                key("home.stt.listening")
            }

            /// "현재 위치를 기반으로 버스 정보를 검색합니다."
            static var searchBasedOnLocation: LocalizedStringKey {
                key("home.stt.searchBasedOnLocation")
            }
        }

        enum A11y {
            enum Button {
                enum Mic {
                    /// "타야할 버스 번호 음성 입력 버튼"
                    static var label: LocalizedStringKey {
                        key("home.a11y.button.mic.label")
                    }

                    enum Hint {
                        /// "아직 주변 정류장을 찾는 중입니다. 잠시만 기다려주세요."
                        static var loading: LocalizedStringKey {
                            key("home.a11y.button.mic.hint.loading")
                        }

                        /// "주변 정류장을 찾지 못했습니다. 위치 권한을 확인하거나 다시 시도해 주세요."
                        static var noStop: LocalizedStringKey {
                            key("home.a11y.button.mic.hint.noStop")
                        }

                        /// "음성으로 타야할 버스를 검색하려면 두 번 탭해주세요."
                        static var ready: LocalizedStringKey {
                            key("home.a11y.button.mic.hint.ready")
                        }
                    }
                }
            }

            enum Announcement {
                /// "주변 정류장 정보를 불러오고 있습니다."
                static var loading: LocalizedStringKey {
                    key("home.a11y.announcement.loading")
                }

                /// "근처 정류장 정보를 불러오고 있습니다."
                static var loadingNearby: LocalizedStringKey {
                    key("home.a11y.announcement.loadingNearby")
                }
            }
        }

        enum Ui {}
    }

    enum Permission {
        enum Button {
            /// "설정으로 이동"
            static var goToSettings: LocalizedStringKey {
                key("permission.button.goToSettings")
            }
        }

        enum Camera {
            /// "버스 번호 인식을 위해 사용"
            static var reason: LocalizedStringKey {
                key("permission.camera.reason")
            }

            /// "카메라 접근"
            static var title: LocalizedStringKey {
                key("permission.camera.title")
            }
        }

        enum Location {
            /// "사용자 위치 기반 정류장 안내를 위해 사용"
            static var reason: LocalizedStringKey {
                key("permission.location.reason")
            }

            /// "위치 정보 접근"
            static var title: LocalizedStringKey {
                key("permission.location.title")
            }
        }

        enum Mic {
            /// "음성 검색 기능을 위해 사용"
            static var reason: LocalizedStringKey {
                key("permission.mic.reason")
            }

            /// "마이크 접근"
            static var title: LocalizedStringKey {
                key("permission.mic.title")
            }
        }

        enum Prompt {
            /// "버스온다를 사용하고 정보를\\n위치, 카메라 및 마이크 접근을 허용해 주세요."
            static var all: LocalizedStringKey {
                key("permission.prompt.all")
            }

            /// "버스온다에 접근\\n권한이 필요합니다."
            static var title: LocalizedStringKey {
                key("permission.prompt.title")
            }
        }

        enum A11y {
            enum Status {
                /// "거절됨"
                static var denied: LocalizedStringKey {
                    key("permission.a11y.status.denied")
                }

                /// "승인됨"
                static var granted: LocalizedStringKey {
                    key("permission.a11y.status.granted")
                }
            }
        }
    }

    /// Accessibility-only formats for BusArrival screens
    enum BusArrival {
        enum A11y {
            enum Format {
                /// "%@번"
                static var routeNumber: LocalizedStringKey {
                    key("busArrival.a11y.format.routeNumber")
                }

                /// "도착 예정"
                static var arriving: LocalizedStringKey {
                    key("busArrival.a11y.format.arriving")
                }

                /// "도착"
                static var arrived: LocalizedStringKey {
                    key("busArrival.a11y.format.arrived")
                }

                /// "%@번째전 정류장에서 출발했습니다."
                static var stopsAway: LocalizedStringKey {
                    key("busArrival.a11y.format.stopsAway")
                }

                /// "전 정류장에서 출발했습니다."
                static var previousStop: LocalizedStringKey {
                    key("busArrival.a11y.format.previousStop")
                }

                /// "잠시 후"
                static var soon: LocalizedStringKey {
                    key("busArrival.a11y.format.soon")
                }

                /// "정보 없음"
                static var noInfo: LocalizedStringKey {
                    key("busArrival.a11y.format.noInfo")
                }

                /// "%@분 %@초 후"
                static var minutesSeconds: LocalizedStringKey {
                    key("busArrival.a11y.format.minutesSeconds")
                }

                /// "%@초 후"
                static var seconds: LocalizedStringKey {
                    key("busArrival.a11y.format.seconds")
                }
            }
        }
    }

    enum SttTtsTest {
        enum Ui {
            /// "키보드 내리기" (문맥: STT/TTS 테스트: 키보드 내리기 버튼)
            static var buttonDismissKeyboard: LocalizedStringKey {
                key("sttTtsTest.ui.button.dismissKeyboard")
            }

            /// "읽기" (문맥: STT/TTS 테스트: TTS 읽기 버튼)
            static var buttonRead: LocalizedStringKey {
                key("sttTtsTest.ui.button.read")
            }

            /// "🎙️ 인식 시작" (문맥: STT/TTS 테스트: STT 인식 시작 버튼)
            static var buttonStartListening: LocalizedStringKey {
                key("sttTtsTest.ui.button.startListening")
            }

            /// "정지" (문맥: STT/TTS 테스트: TTS 정지 버튼)
            static var buttonStop: LocalizedStringKey {
                key("sttTtsTest.ui.button.stop")
            }

            /// "🛑 인식 중지" (문맥: STT/TTS 테스트: STT 인식 중지 버튼)
            static var buttonStopListening: LocalizedStringKey {
                key("sttTtsTest.ui.button.stopListening")
            }

            /// "여기에 인식된 텍스트가 표시됩니다." (문맥: STT/TTS 테스트: STT 결과 플레이스홀더)
            static var placeholderStt: LocalizedStringKey {
                key("sttTtsTest.ui.placeholder.stt")
            }

            /// "텍스트를 입력하세요" (문맥: STT/TTS 테스트: TTS 입력 플레이스홀더)
            static var placeholderTts: LocalizedStringKey {
                key("sttTtsTest.ui.placeholder.tts")
            }

            /// "STT&TTS 테스트 페이지" (문맥: STT/TTS 테스트: 내비게이션 타이틀)
            static var titleNavigation: LocalizedStringKey {
                key("sttTtsTest.ui.title.navigation")
            }

            /// "음성 받아적기 테스트" (문맥: STT/TTS 테스트: STT 섹션 타이틀)
            static var titleStt: LocalizedStringKey {
                key("sttTtsTest.ui.title.stt")
            }

            /// "읽을 텍스트" (문맥: STT/TTS 테스트: TTS 섹션 타이틀)
            static var titleTts: LocalizedStringKey {
                key("sttTtsTest.ui.title.tts")
            }
        }
    }

    enum Test {
        enum Ui {
            /// "정류장 기준 전체 도착 예정 정보" (문맥: 테스트: 정류장 도착 정보 버튼 서브타이틀)
            static var buttonArrivalsSubtitle: LocalizedStringKey {
                key("test.ui.button.arrivals.subtitle")
            }

            /// "정류장 도착 정보" (문맥: 테스트: 정류장 도착 정보 버튼 타이틀)
            static var buttonArrivalsTitle: LocalizedStringKey {
                key("test.ui.button.arrivals.title")
            }

            /// "정류장 + 노선 조합으로 도착 조회" (문맥: 테스트: 특정 노선 도착 정보 버튼 서브타이틀)
            static var buttonArrivalsForRouteSubtitle: LocalizedStringKey {
                key("test.ui.button.arrivalsForRoute.subtitle")
            }

            /// "특정 노선 도착 정보" (문맥: 테스트: 특정 노선 도착 정보 버튼 타이틀)
            static var buttonArrivalsForRouteTitle: LocalizedStringKey {
                key("test.ui.button.arrivalsForRoute.title")
            }

            /// "선택한 노선의 차량 위치 추적" (문맥: 테스트: 차량 실시간 위치 버튼 서브타이틀)
            static var buttonRouteBusLocationsSubtitle: LocalizedStringKey {
                key("test.ui.button.routeBusLocations.subtitle")
            }

            /// "차량 실시간 위치" (문맥: 테스트: 차량 실시간 위치 버튼 타이틀)
            static var buttonRouteBusLocationsTitle: LocalizedStringKey {
                key("test.ui.button.routeBusLocations.title")
            }

            /// "첫/막차 시간 등 노선 상세 확인" (문맥: 테스트: 노선 기본 정보 버튼 서브타이틀)
            static var buttonRouteInfoSubtitle: LocalizedStringKey {
                key("test.ui.button.routeInfo.subtitle")
            }

            /// "노선 기본 정보" (문맥: 테스트: 노선 기본 정보 버튼 타이틀)
            static var buttonRouteInfoTitle: LocalizedStringKey {
                key("test.ui.button.routeInfo.title")
            }

            /// "노선이 지나가는 정류장 순서 확인" (문맥: 테스트: 노선 경유 정류장 버튼 서브타이틀)
            static var buttonRouteStopsSubtitle: LocalizedStringKey {
                key("test.ui.button.routeStops.subtitle")
            }

            /// "노선 경유 정류장" (문맥: 테스트: 노선 경유 정류장 버튼 타이틀)
            static var buttonRouteStopsTitle: LocalizedStringKey {
                key("test.ui.button.routeStops.title")
            }

            /// "노선 번호 키워드로 노선 찾기" (문맥: 테스트: 노선 번호 검색 버튼 서브타이틀)
            static var buttonSearchRouteSubtitle: LocalizedStringKey {
                key("test.ui.button.searchRoute.subtitle")
            }

            /// "노선 번호 검색" (문맥: 테스트: 노선 번호 검색 버튼 타이틀)
            static var buttonSearchRouteTitle: LocalizedStringKey {
                key("test.ui.button.searchRoute.title")
            }

            /// "도시 코드와 정류장 이름으로 조회" (문맥: 테스트: 정류장 키워드 검색 버튼 서브타이틀)
            static var buttonSearchStopSubtitle: LocalizedStringKey {
                key("test.ui.button.searchStop.subtitle")
            }

            /// "정류장 키워드 검색" (문맥: 테스트: 정류장 키워드 검색 버튼 타이틀)
            static var buttonSearchStopTitle: LocalizedStringKey {
                key("test.ui.button.searchStop.title")
            }

            /// "선택한 정류장을 통과하는 노선 목록" (문맥: 테스트: 정류장을 지나는 노선 버튼 서브타이틀)
            static var buttonStopRoutesSubtitle: LocalizedStringKey {
                key("test.ui.button.stopRoutes.subtitle")
            }

            /// "정류장을 지나는 노선" (문맥: 테스트: 정류장을 지나는 노선 버튼 타이틀)
            static var buttonStopRoutesTitle: LocalizedStringKey {
                key("test.ui.button.stopRoutes.title")
            }

            /// "현재 좌표 기준으로 반경 검색" (문맥: 테스트: 현위치 주변 정류장 버튼 서브타이틀)
            static var buttonStopsByGpsSubtitle: LocalizedStringKey {
                key("test.ui.button.stopsByGps.subtitle")
            }

            /// "현위치 주변 정류장" (문맥: 테스트: 현위치 주변 정류장 버튼 타이틀)
            static var buttonStopsByGpsTitle: LocalizedStringKey {
                key("test.ui.button.stopsByGps.title")
            }

            /// "테스트 API 호출" (문맥: 테스트: API 호출 섹션 타이틀)
            static var labelApiCall: LocalizedStringKey {
                key("test.ui.label.apiCall")
            }

            /// "cityCode" (문맥: 테스트: cityCode 레이블)
            static var labelCityCode: LocalizedStringKey {
                key("test.ui.label.cityCode")
            }

            /// "위도/경도" (문맥: 테스트: 위도/경도 레이블)
            static var labelCoordinates: LocalizedStringKey {
                key("test.ui.label.coordinates")
            }

            /// "nodeId" (문맥: 테스트: nodeId 레이블)
            static var labelNodeId: LocalizedStringKey {
                key("test.ui.label.nodeId")
            }

            /// "원본 응답(JSON)" (문맥: 테스트: 원본 응답 레이블)
            static var labelRawResponse: LocalizedStringKey {
                key("test.ui.label.rawResponse")
            }

            /// "응답 미리보기" (문맥: 테스트: 응답 미리보기 레이블)
            static var labelResponsePreview: LocalizedStringKey {
                key("test.ui.label.responsePreview")
            }

            /// "노선 ID/노선 번호" (문맥: 테스트: 노선 레이블)
            static var labelRoute: LocalizedStringKey {
                key("test.ui.label.route")
            }

            /// "검색어" (문맥: 테스트: 검색어 레이블)
            static var labelSearchTerm: LocalizedStringKey {
                key("test.ui.label.searchTerm")
            }

            /// "검색어 없음" (문맥: 테스트: 검색어 없음 플레이스홀더)
            static var placeholderNoSearchTerm: LocalizedStringKey {
                key("test.ui.placeholder.noSearchTerm")
            }

            /// "도착 정보" (문맥: 테스트: 도착 정보 섹션 타이틀)
            static var titleArrivalSection: LocalizedStringKey {
                key("test.ui.title.arrivalSection")
            }

            /// "버스 API 테스트" (문맥: 테스트: 내비게이션 타이틀)
            static var titleNavigation: LocalizedStringKey {
                key("test.ui.title.navigation")
            }

            /// "노선 정보" (문맥: 테스트: 노선 정보 섹션 타이틀)
            static var titleRouteSection: LocalizedStringKey {
                key("test.ui.title.routeSection")
            }

            /// "정류장 조회" (문맥: 테스트: 정류장 조회 섹션 타이틀)
            static var titleStopSection: LocalizedStringKey {
                key("test.ui.title.stopSection")
            }

            /// "Seoul API Tests" (문맥: 테스트: 서울 API 테스트 섹션 타이틀)
            static var titleSeoulSection: LocalizedStringKey {
                key("test.ui.title.seoulSection")
            }

            /// "Test Profile" (문맥: 테스트: 프로필 선택 라벨)
            static var pickerProfile: LocalizedStringKey {
                key("test.ui.picker.profile")
            }

            /// "Seoul" (문맥: 테스트: 프로필 이름)
            static var profileSeoul: LocalizedStringKey {
                key("test.ui.profile.seoul")
            }

            /// "Pangyo" (문맥: 테스트: 프로필 이름)
            static var profilePangyo: LocalizedStringKey {
                key("test.ui.profile.pangyo")
            }
        }
    }

    enum K {
        /// "버스온다"
        static var appName: LocalizedStringKey {
            key("k.appName")
        }
    }
}
