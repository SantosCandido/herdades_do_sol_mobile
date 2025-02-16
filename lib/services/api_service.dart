import 'package:dio/dio.dart';
import 'dart:io';

class ApiService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://10.0.2.2:8000/api/',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Accept': 'application/json'},
    validateStatus: (status) {
      return status != null && status < 500;
    },
  ));

  // Register method
  Future<Response> registerUser(Map<String, dynamic> userData) async {
    try {
      final response = await _dio.post(
        'register',
        data: userData,
        options: Options(
          validateStatus: (status) {
            return status != null && status < 500;
          },
        ),
      );

      if (response.statusCode == 422) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Validation error',
          type: DioExceptionType.badResponse,
        );
      }
      return response;
    } catch (e) {
      throw e;
    }
  }

  // Login method
  Future<Response> login(String email, String password) async {
    try {
      final response = await _dio.post(
        'login',
        data: {'email': email, 'password': password},
        options: Options(
          validateStatus: (status) {
            return status != null && status < 500;
          },
        ),
      );

      if (response.statusCode == 401) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Invalid credentials',
          type: DioExceptionType.badResponse,
        );
      }

      return response;
    } catch (e) {
      throw e;
    }
  }

  // Logout method
  Future<Response> logout(String token) async {
    try {
      final response = await _dio.post(
        'logout',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response;
    } on DioException catch (e) {
      throw Exception('Failed to logout: ${e.response?.data['error'] ?? e.message}');
    }
  }

  // Update UserApp method
  Future<Response> getUserData(String token) async {
    try {
      final response = await _dio.get(
        'user',
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        }),
      );
      return response;
    } on DioException catch (e) {
      throw Exception('Failed to fetch user data: ${e.response?.data['error'] ?? e.message}');
    }
  }

  // Edit User method
  Future<Response> editUser(String token, Map<String, dynamic> userData, File? imageFile) async {
    try {
      FormData formData = FormData.fromMap(userData);

      if (imageFile != null) {
        formData.files.add(MapEntry(
          'img',
          await MultipartFile.fromFile(imageFile.path, filename: imageFile.path.split('/').last),
        ));
      }

      final response = await _dio.post(
        'edit',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return response;
    } on DioException catch (e) {
      throw Exception('Failed to edit user: ${e.response?.data['error'] ?? e.message}');
    }
  }

  // Get User Billing Information method
  Future<Response> getBillingInfo(String token) async {
    try {
      final response = await _dio.get(
        'billing',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response;
    } on DioException catch (e) {
      throw Exception('Failed to fetch billing info: ${e.response?.data['error'] ?? e.message}');
    }
  }

  // Update User Billing Information method
  Future<Response> updateBillingInfo(String token, Map<String, dynamic> billingData) async {
    try {
      final response = await _dio.post(
        'billing/update',
        data: billingData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response;
    } on DioException catch (e) {
      throw Exception('Failed to update billing info: ${e.response?.data['error'] ?? e.message}');
    }
  }

  // Update User Billing Address method
  Future<Response> updateBillingAddress(String token, Map<String, dynamic> addressData) async {
    try {
      final response = await _dio.post(
        'billing/address/update',
        data: addressData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response;
    } on DioException catch (e) {
      throw Exception('Failed to update billing address: ${e.response?.data['error'] ?? e.message}');
    }
  }

  // Get User Payment methods
  Future<Response> getPaymentMethods(String token) async {
    try {
      final response = await _dio.get(
        'payment-methods',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response;
    } on DioException catch (e) {
      throw Exception('Failed to fetch payment methods: ${e.response?.data ?? e.message}');
    }
  }

  // Add Payment method
  Future<Response> addPaymentMethod(String token, Map<String, dynamic> paymentData) async {
    return await _dio.post(
      'payment-methods',
      data: paymentData,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  // Delete Payment method
  Future<void> deletePaymentMethod(String token, int paymentMethodId) async {
    try {
      await _dio.delete(
        'payment-methods/$paymentMethodId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      throw Exception('Failed to delete payment method: ${e.response?.data['error'] ?? e.message}');
    }
  }

  // Set Default Payment method
  Future<Response> setDefaultPaymentMethod(String token, int paymentId) async {
    return await _dio.post(
      'payment-methods/$paymentId/set-default',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  // Get Estates method
  Future<List<dynamic>> getEstates() async {
    final response = await _dio.get('/estates');
    return response.data['estates'];
  }

  // Get Accommodations method
  Future<List<dynamic>> getAccommodations() async {
    final response = await _dio.get('/accommodations');
    return response.data['accommodations'];
  }

  // Get Available Accommodations Types method
  Future<List<dynamic>> getAvailableAccommodationTypes(String estateId, String checkIn, String checkOut, int groupSize) async {
    final response = await _dio.get(
      '/accommodations/types',
      queryParameters: {
        'estate_id': estateId,
        'check_in': checkIn,
        'check_out': checkOut,
        'group_size': groupSize,
      },
    );

    return response.data['accommodation_types'];
  }

  // Get Available Accommodations method
  Future<List<dynamic>> getAvailableAccommodations(String estateId, String checkIn, String checkOut, int groupSize, String accommodationTypeId) async {
    final response = await _dio.get(
      '/accommodations/available',
      queryParameters: {
        'estate_id': estateId,
        'check_in': checkIn,
        'check_out': checkOut,
        'group_size': groupSize,
        'accommodation_type_id': accommodationTypeId,
      },
    );

    return response.data['accommodations'];
  }

  // Get Activities by Estate and Date method
  Future<List<dynamic>> getActivitiesByEstateAndDate(String estateId, String checkIn, String checkOut, int groupSize, int children) async {
    final response = await _dio.get(
      '/activities/by-date',
      queryParameters: {
        'estate_id': estateId,
        'check_in': checkIn,
        'check_out': checkOut,
        'group_size': groupSize,
        'children': children,
      },
    );

    return response.data['activities'];
  }

  // Get Accommodations Type method
  Future<List<dynamic>> getAccommodationTypes() async {
    final response = await _dio.get('/accommodation-types');
    return response.data;
  }

  // Get Activities method
  Future<List<dynamic>> getActivities() async {
    final response = await _dio.get('/activities');
    return response.data;
  }

  // Book method
  Future<Response> bookReservation(String token, Map<String, dynamic> reservationData) async {
    return await _dio.post(
      '/book-reservation',
      data: reservationData,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  // Get Reservations method
  Future<Response> getTrips(String token) async {
    return _dio.get(
      '/trips',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  // Get Notifications
  Future<Response> getNotifications(String token) async {
    return _dio.get(
      "/notifications",
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );
  }

  // Mark Notifications
  Future<Response> markNotificationsAsRead(String token) async {
    return _dio.post(
      "/notifications/mark-read",
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );
  }
}