import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';

/// 위치 기반 서비스
class LocationService extends GetxService {
  static LocationService get to => Get.find();
  
  final _currentPosition = Rx<Position?>(null);
  final _isLoading = false.obs;
  final _error = RxString('');
  
  Position? get currentPosition => _currentPosition.value;
  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  
  @override
  void onInit() {
    super.onInit();
    _checkPermissions();
  }
  
  /// 위치 권한 확인 및 요청
  Future<bool> _checkPermissions() async {
    try {
      // 위치 권한 상태 확인
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        // 권한이 거부된 경우 요청
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _error.value = '위치 권한이 거부되었습니다.';
          return false;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        _error.value = '위치 권한이 영구적으로 거부되었습니다. 설정에서 권한을 허용해주세요.';
        return false;
      }
      
      return true;
    } catch (e) {
      _error.value = '위치 권한 확인 중 오류가 발생했습니다: $e';
      return false;
    }
  }
  
  /// 현재 위치 가져오기
  Future<Position?> getCurrentLocation() async {
    try {
      _isLoading.value = true;
      _error.value = '';
      
      // 권한 확인
      if (!await _checkPermissions()) {
        return null;
      }
      
      // 위치 서비스 활성화 확인
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _error.value = '위치 서비스가 비활성화되어 있습니다.';
        return null;
      }
      
      // 현재 위치 가져오기
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      _currentPosition.value = position;
      return position;
    } catch (e) {
      _error.value = '위치를 가져오는 중 오류가 발생했습니다: $e';
      return null;
    } finally {
      _isLoading.value = false;
    }
  }
  
  /// 두 지점 간의 거리 계산 (미터 단위)
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }
  
  /// 거리를 사람이 읽기 쉬운 형태로 변환
  String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()}m';
    } else {
      double km = distanceInMeters / 1000;
      return '${km.toStringAsFixed(1)}km';
    }
  }
  
  /// 위치 기반 사용자 정렬
  List<Map<String, dynamic>> sortUsersByDistance(
    List<Map<String, dynamic>> users,
    Position currentPosition,
  ) {
    if (users.isEmpty) return users;
    
    // 각 사용자에 거리 정보 추가
    final usersWithDistance = users.map((user) {
      final userLat = user['latitude'] as double?;
      final userLon = user['longitude'] as double?;
      
      if (userLat != null && userLon != null) {
        final distance = calculateDistance(
          currentPosition.latitude,
          currentPosition.longitude,
          userLat,
          userLon,
        );
        return {
          ...user,
          'distance': distance,
          'formattedDistance': formatDistance(distance),
        };
      } else {
        return {
          ...user,
          'distance': double.infinity,
          'formattedDistance': '위치 정보 없음',
        };
      }
    }).toList();
    
    // 거리순으로 정렬 (가까운 순)
    usersWithDistance.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));
    
    return usersWithDistance;
  }
  
  /// 위치 권한 설정으로 이동
  Future<void> openLocationSettings() async {
    await openAppSettings();
  }
}
