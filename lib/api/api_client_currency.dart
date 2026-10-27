part of 'api_client.dart';

extension ApiClientCurrencyX on ApiClient {
  /// Reads the latest asset snapshot written by `tasks/CurrencySnapshot`.
  ///
  /// The request carries a cache-busting query parameter so the panel always
  /// reflects the file on disk instead of a cached copy.
  Future<ApiResult<CurrencySnapshot>> getCurrencySnapshot() async {
    final res = await request(
      () => get(
        '/currency/latest',
        queryParameters: {'_': DateTime.now().millisecondsSinceEpoch},
      ),
    );
    if (!res.isSuccess) {
      return ApiResult.failure(res.error, res.code);
    }
    final data = res.data;
    if (data is! Map) {
      return ApiResult.failure('Invalid currency snapshot response');
    }
    return ApiResult.success(
      CurrencySnapshot.fromJson(Map<String, dynamic>.from(data)),
    );
  }

  /// Reads the snapshot history used by the date picker and the deltas.
  Future<ApiResult<CurrencyHistory>> getCurrencyHistory({
    int limit = 120,
  }) async {
    final res = await request(
      () => get(
        '/currency/history',
        queryParameters: {
          'limit': limit,
          '_': DateTime.now().millisecondsSinceEpoch,
        },
      ),
    );
    if (!res.isSuccess) {
      return ApiResult.failure(res.error, res.code);
    }
    final data = res.data;
    if (data is! Map) {
      return ApiResult.failure('Invalid currency history response');
    }
    return ApiResult.success(
      CurrencyHistory.fromJson(Map<String, dynamic>.from(data)),
    );
  }
}
