import 'package:dartz/dartz.dart';
import 'package:efs_misr/Features/Home/data/data_source/remote_data_source.dart';
import 'package:efs_misr/Features/Home/data/models/assets.dart';
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
  Future<Either<Failure, List<Assets>>> getAssets() async{
    try {
      final assets = await homeRemoteDataSource.getAssets();
      return Right(assets);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, Assets>> getAssetsByQrCode(String barcode) async{
try{
  final assets = await homeRemoteDataSource.getAssetsByQrCode(barcode);
  return Right(assets);
}
    catch(e){
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, List<Users>>> getUsers() async{
    try{
      final users = await homeRemoteDataSource.getUsers();
      return Right(users);
    }
        catch(e){
      return Left(Failure.fromException(e));
        }
  }

  @override
  Future<Either<Failure, Tickets>> updateTicketStatus({required String ticketID, required String newStatus}) async{
    try{
      final tickets =await supabaseClient.tickets.update(Tickets.update(
        status: newStatus,
      )).eq('id', ticketID).select().single().withConverter(Tickets.converterSingle);
      return Right(tickets);

    }
        catch(e){
      return Left(Failure.fromException(e));
        }
  }

  @override
  Future<Either<Failure, List<Tickets>>> addTicket({required BigInt orecalID, required String comment, required BigInt branchID, required String priority, required DateTime requestDate, required BigInt engineer}) async{
    try{
   final tickets =   await supabaseClient.tickets.insert(Tickets.insert(
        orecalId: orecalID,
        comment: comment,
        branch: branchID,
        priority: priority,
        requestDate: requestDate,
        engineer: engineer,
      )).select().withConverter(Tickets.converter);
      return  Right(tickets);
    }
        catch(e){
      return Left(Failure.fromException(e));
        }
  }


}
