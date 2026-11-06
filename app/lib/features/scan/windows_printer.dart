/// Windows 端蓝牙 SPP 打印（纯 Dart FFI）。
///
/// 只走经典蓝牙 RFCOMM：`socket(AF_BTH, SOCK_STREAM, BTHPROTO_RFCOMM)` +
/// `connect(SOCKADDR_BTH)` + `send`。不折腾虚拟串口（那条路要读注册表找
/// COM 号，且串口名在不同机器上不稳定）。
///
/// 前提：打印机已经在 Windows「设置 → 蓝牙和其他设备」里配对成功。
/// 配对有 PIN 交互，App 无法代劳。
library;

import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
// ws2_32（socket/connect/send/closesocket）不在 win32.dart 里，单独从 winsock2 导。
import 'package:win32/winsock2.dart';

import 'printer_channel.dart';

/// RFCOMM 协议号。win32 包没导出这个常量。
const int _bthProtoRfcomm = 0x0003;

/// SPP 打印机的 RFCOMM 通道基本是 1；连不上就依次试 2/3/4。
const int _maxPortAttempts = 4;

/// 懒加载：这个文件只在 Windows 分支被用到，但测试会 import 它，
/// 顶层直接 open 会让非 Windows 环境在导入时就崩。
DynamicLibrary? _ws2Cache;
DynamicLibrary get _ws2 => _ws2Cache ??= DynamicLibrary.open('ws2_32.dll');

int Function(int, Pointer<Uint8>) get _wsaStartup => _ws2.lookupFunction<
    Int32 Function(Uint16, Pointer<Uint8>),
    int Function(int, Pointer<Uint8>)>('WSAStartup');

int Function() get _wsaGetLastError =>
    _ws2.lookupFunction<Int32 Function(), int Function()>('WSAGetLastError');

/// 顶层包装：类里有个同名方法 `connect`，直接调全局 `connect` 会被遮蔽。
int _wsConnect(int sock, Pointer<SOCKADDR_BTH> addr) =>
    connect(sock, addr.cast<SOCKADDR>(), sizeOf<SOCKADDR_BTH>());

/// 第 [attempt] 次尝试用哪个 RFCOMM 端口；用完之后返回 null。
int? nextRfcommPort(int attempt) =>
    attempt >= 0 && attempt < _maxPortAttempts ? attempt + 1 : null;

/// `AA:BB:CC:DD:EE:FF` → 48 bit 整数（Windows 的 `btAddr`）。
///
/// 不能简单 `int.parse` 之后移位：Windows 展示的是高位在前，而 `btAddr`
/// 里低 8 位是地址的第一个字节。这里按 [12 位十六进制整体解析] 得到
/// `0xAABBCCDDEEFF`，与 SOCKADDR_BTH 的布局一致。
int parseBluetoothAddress(String address) {
  final hex = address.replaceAll(RegExp('[:-]'), '');
  if (hex.length != 12) {
    throw ArgumentError.value(
      address,
      'address',
      '蓝牙地址必须是 AA:BB:CC:DD:EE:FF 这种 12 位十六进制',
    );
  }
  final value = int.tryParse(hex, radix: 16);
  if (value == null) {
    throw ArgumentError.value(address, 'address', '蓝牙地址含非十六进制字符');
  }
  return value;
}

/// 48 bit 整数 → `AA:BB:CC:DD:EE:FF`。
String formatBluetoothAddress(int value) {
  final parts = <String>[];
  for (var i = 5; i >= 0; i--) {
    parts.add(((value >> (i * 8)) & 0xFF).toRadixString(16).padLeft(2, '0'));
  }
  return parts.join(':').toUpperCase();
}

class WindowsPrinterChannel implements PrinterChannel {
  int _socket = -1;
  bool _wsaReady = false;
  int? _workingPort;
  PrinterDevice? _connected;

  @override
  Future<List<PrinterDevice>> scan() async => _enumeratePaired();

  @override
  Future<void> connect(String address) async {
    final mac = parseBluetoothAddress(address);
    _ensureWinsock();

    final tried = <int>[];
    int? firstError;
    var attempt = 0;

    while (true) {
      final port = _workingPort ?? nextRfcommPort(attempt);
      if (port == null) break;
      tried.add(port);

      final rc = _openAndConnect(mac, port);
      if (rc == 0) {
        _workingPort = port;
        _connected = PrinterDevice(name: address, address: address);
        return;
      }

      firstError ??= _wsaGetLastError();
      _closeSocket();
      attempt++;
    }

    throw PrinterException(
      'connect_failed',
      '连不上 $address（试过端口 ${tried.join('/')}，错误码 ${firstError ?? '未知'}）。'
      '确认打印机已开机，并已在 Windows 设置里配对。',
    );
  }

  @override
  Future<void> disconnect() async {
    _closeSocket();
    _connected = null;
  }

  @override
  Future<bool> isConnected() async => _socket >= 0;

  @override
  Future<void> write(List<int> bytes) async {
    if (_socket < 0) {
      throw const PrinterException('not_connected', '还没连上打印机');
    }
    if (bytes.isEmpty) {
      throw const PrinterException('empty_payload', '没有要发送的内容');
    }

    final data = Uint8List.fromList(bytes);
    final buffer = calloc<Uint8>(data.length);
    try {
      buffer.asTypedList(data.length).setAll(0, data);

      var offset = 0;
      while (offset < data.length) {
        final sent = send(
          _socket,
          (buffer + offset).cast<Utf8>(),
          data.length - offset,
          0,
        );
        if (sent <= 0) {
          final error = _wsaGetLastError();
          _closeSocket();
          throw PrinterException('write_failed', '发送失败（错误码 $error）');
        }
        offset += sent;
      }
    } finally {
      calloc.free(buffer);
    }
  }

  /// 当前是否已连上（给 UI 用）。
  bool get attached => _socket >= 0;

  /// 当前连接对应的设备地址（给 UI 用）。
  PrinterDevice? get device => _connected;

  // ---------------------------------------------------------------------

  void _ensureWinsock() {
    if (_wsaReady) return;
    final data = calloc<Uint8>(512); // WSADATA 约 400 字节，留余量
    try {
      final rc = _wsaStartup(0x0202, data); // MAKEWORD(2, 2)
      if (rc != 0) {
        throw PrinterException('wsa_failed', 'Winsock 初始化失败（$rc）');
      }
      _wsaReady = true;
    } finally {
      calloc.free(data);
    }
  }

  /// 返回 0 表示连上，其它值是 `connect` 的返回值。
  int _openAndConnect(int mac, int port) {
    _closeSocket();

    final sock = socket(AF_BTH, SOCK_STREAM, _bthProtoRfcomm);
    if (sock < 0) return -1;

    final addr = calloc<SOCKADDR_BTH>();
    try {
      addr.ref.addressFamily = AF_BTH;
      addr.ref.btAddr = mac;
      addr.ref.port = port;
      // serviceClassId 留全零 = GUID_NULL（calloc 已经清零）。

      final rc = _wsConnect(sock, addr);
      if (rc != 0) {
        closesocket(sock);
        return rc;
      }
      _socket = sock;
      return 0;
    } finally {
      calloc.free(addr);
    }
  }

  void _closeSocket() {
    if (_socket >= 0) {
      closesocket(_socket);
      _socket = -1;
    }
  }

  List<PrinterDevice> _enumeratePaired() {
    final params = calloc<BLUETOOTH_DEVICE_SEARCH_PARAMS>();
    final info = calloc<BLUETOOTH_DEVICE_INFO>();

    try {
      params.ref.dwSize = sizeOf<BLUETOOTH_DEVICE_SEARCH_PARAMS>();
      params.ref.fReturnAuthenticated = 1;
      params.ref.fReturnRemembered = 1;
      params.ref.fReturnConnected = 1;
      params.ref.fReturnUnknown = 0;
      params.ref.fIssueInquiry = 0; // 不做新的搜索，只看系统里已有的
      params.ref.cTimeoutMultiplier = 1;
      params.ref.hRadio = 0;

      info.ref.dwSize = sizeOf<BLUETOOTH_DEVICE_INFO>();

      final find = BluetoothFindFirstDevice(params, info);
      if (find == 0) return const [];

      final result = <PrinterDevice>[];
      try {
        do {
          final name = info.ref.szName.trim();
          result.add(
            PrinterDevice(
              name: name.isEmpty ? '未命名设备' : name,
              address: formatBluetoothAddress(info.ref.Address.ullLong),
            ),
          );
        } while (BluetoothFindNextDevice(find, info) != 0);
      } finally {
        BluetoothFindDeviceClose(find);
      }
      return result;
    } finally {
      calloc.free(params);
      calloc.free(info);
    }
  }
}
