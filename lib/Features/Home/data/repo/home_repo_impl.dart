import 'package:dartz/dartz.dart';
import 'package:efs_misr/Features/Home/data/data_source/remote_data_source.dart';
import 'package:efs_misr/Features/Home/data/models/assets.dart';
import 'package:efs_misr/Features/Home/data/models/assets_and_tickets.dart';
import 'package:efs_misr/Features/Home/data/models/assets_repair.dart';
import 'package:efs_misr/Features/Home/data/models/supadart_header.dart';
import 'package:efs_misr/Features/Home/data/models/tickets.dart';
import 'package:efs_misr/Features/Home/domain/repo/home_repo.dart';
import 'package:efs_misr/constants/constants.dart';
import 'package:efs_misr/core/Errors/failure.dart';

import '../models/user.dart';

class HomeRepoImpl extends HomeRepo {
  HomeRemoteDataSource homeRemoteDataSource;

  HomeRepoImpl(this.homeRemoteDataSource);

  @override
  Future<Either<Failure, List<Tickets>>> getTickets() async {
    try {
      final tickets = await homeRemoteDataSource.getTickets();
      return Right(tickets);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, List<Assets>>> getAssets() async {
    try {
      final assets = await homeRemoteDataSource.getAssets();
      return Right(assets);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, Assets>> getAssetsByQrCode(String barcode) async {
    try {
      final assets = await homeRemoteDataSource.getAssetsByQrCode(barcode);
      return Right(assets);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, List<Users>>> getUsers() async {
    try {
      final users = await homeRemoteDataSource.getUsers();
      return Right(users);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, Tickets>> updateTicketStatus({
    required String ticketID,
    required String newStatus,
    required DateTime repairDate,
  }) async {
    try {
      final tickets = await supabaseClient.tickets
          .update(Tickets.update(status: newStatus, repairDate: repairDate))
          .eq('id', ticketID)
          .select('''
      *,
      branch(*),
      engineer:users!tickets_engineer_fkey(*,positions(*))
    ''')
          .single()
          .withConverter(Tickets.converterSingle);
      return Right(tickets);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, List<Tickets>>> addTicket({
    required BigInt orecalID,
    required String comment,
    required BigInt branchID,
    required String priority,
    required DateTime requestDate,
    required BigInt engineer,
  }) async {
    try {
      final tickets = await supabaseClient.tickets
          .insert(
            Tickets.insert(
              orecalId: orecalID,
              comment: comment,
              branch: branchID,
              priority: priority,
              requestDate: requestDate,
              engineer: engineer,
            ),
          )
          .select()
          .withConverter(Tickets.converter);
      return Right(tickets);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, String>> addAssetsAndTickets({
    required BigInt assetsId,
    required BigInt ticketId,
  }) async {
    try {
      await supabaseClient.assetsAndTickets.insert(
        AssetsAndTickets.insert(assetsId: assetsId, TicketsId: ticketId),
      );
      return Right('Success');
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, List<Assets>>> getAssetsWithTicketID({
    required BigInt ticketId,
  }) async {
    try {
      final assetsAndTickets = await homeRemoteDataSource.getAssetsWithTicketID(
        ticketId: ticketId,
      );
      return Right(assetsAndTickets);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, List<Tickets>>> getTicketsWithAssetsID({
    required BigInt assetId,
  }) async {
    try {
      final assetsAndTickets = await homeRemoteDataSource
          .getTicketsWithAssetsID(assetId: assetId);
      return Right(assetsAndTickets);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, Tickets>> updateTicketComment({
    required String ticketID,
    required String newComment,
  }) async {
    try {
      final tickets = await supabaseClient.tickets
          .update(Tickets.update(damageDescription: newComment))
          .eq('id', ticketID)
          .select('''
      *,
      branch(*),
      engineer:users!tickets_engineer_fkey(*,positions(*))
    ''')
          .single()
          .withConverter(Tickets.converterSingle);
      return Right(tickets);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, String>> addAssetsRepairs({
    required BigInt assetsId,
    required BigInt ticketId,
    required String variation,
    required String comment,
    required num amount,
  }) async {
    try {
      await supabaseClient.AssetsRepair.insert(
        AssetsRepair.insert(
          amount: amount,
          TicketsId: ticketId,
          assetsId: assetsId,
          comment: comment,
          variation: variation,
        ),
      ).select();
      return Right('Success');
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, List<AssetsRepair>>> getAssetsRepairWithTicketID({
    required BigInt ticketID,
  }) async {
    try {
      final res = await homeRemoteDataSource.getAssetsRepairDetailsWithTicketId(
        ticketID: ticketID,
      );
      return Right(res);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, List<Users>>> updateUserData({
    required String userID,
    required String? userName,
    required String? phone,
    required String? address,
    required BigInt? position,
    required int? status,
    required String? role,
    required String? companyEmail,
    required String? company,
    required String? email,
    required String? password,
  }) async {
    try {
      final res = await supabaseClient.functions.invoke(
        'update-user',
        body: {'userId': userID, 'email': email, 'password': password},
      );
      final user = await supabaseClient.users
          .update(
            Users.update(
              address: address,
              company: company,
              companyEmail: companyEmail,
              email: email,
              name: userName,
              password: password,
              phone: phone,
              role: role,
              positionID: position,
              status: status,
            ),
          )
          .eq(Users.c_userid, userID)
          .select('*,positions(*)')
          .withConverter(Users.converter);
      return Right(user);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }
}
