import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:expense_tracker/core/helpers/di.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../../models/request_body_model.dart';
import '../source/dio_helper.dart';
import '../utils/dio_options.dart';
import '../utils/handle_errors.dart';

@lazySingleton
class Get extends DioHelper {
  @override
  Future<Either<ServerFailure, Response>> call(RequestBodyModel params) async {
    try {
      var response = await dio.get(params.url, options: getIt<DioOptions>()(forceRefresh: params.forceRefresh));
      return getIt<HandleErrors>().statusError(response, params.errorFunc);
    } on DioError catch (e) {
      getIt<HandleErrors>().catchError(errorFunc: params.errorFunc, response: e.response, e: e);
      return Left(ServerFailure());
    }
  }
}
