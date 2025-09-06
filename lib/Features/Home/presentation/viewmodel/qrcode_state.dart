part of 'qrcode_cubit.dart';

@immutable
sealed class QrcodeState {}

final class QrcodeInitial extends QrcodeState {}
final class QrcodeLoading extends QrcodeState {}
final class QrcodeFailed extends QrcodeState {
  final String errMsg;
  QrcodeFailed({required this.errMsg});
}
final class QrcodeSuccess extends QrcodeState {
  final Assets assets;
  QrcodeSuccess({required this.assets});
}
