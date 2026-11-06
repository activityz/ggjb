package me.local.ggjb

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothSocket
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import android.os.SystemClock
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.util.UUID
import java.util.concurrent.Executors

/**
 * 蓝牙标签打印通道。
 *
 * 为什么自己写而不引 pub 包：现成的打印包会把整个项目的 pub 依赖源搬到
 * pub.dev（实测 247 个 lock 条目变动），而它只提供传输层——TSPL 指令本来
 * 就在 Dart 侧拼。这里只做四件事：扫描、连接、断开、写字节。
 *
 * 通道：ggjb/printer
 */
class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "ggjb/printer"
        private const val PERMISSION_REQUEST = 0x9B1E
        private const val SCAN_WINDOW_MS = 10_000L
        private const val SPP_UUID = "00001101-0000-1000-8000-00805F9B34FB"
    }

    private val io = Executors.newSingleThreadExecutor()
    private var socket: BluetoothSocket? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "scan" -> runIo(result) { scanBlocking() }
                    "connect" -> runIo(result) {
                        connectBlocking(call.argument<String>("address"))
                    }
                    "disconnect" -> {
                        closeSocket()
                        result.success(true)
                    }
                    "isConnected" -> result.success(socket?.isConnected == true)
                    "write" -> runIo(result) {
                        writeBlocking(call.argument<List<Int>>("bytes"))
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        closeSocket()
        io.shutdownNow()
        super.onDestroy()
    }

    /** 蓝牙与 IO 都放后台线程，结果回主线程；异常统一成 Flutter 的 error。 */
    private fun <T> runIo(result: MethodChannel.Result, block: () -> T) {
        io.execute {
            try {
                val value = block()
                runOnUiThread { result.success(value) }
            } catch (e: PrinterError) {
                runOnUiThread { result.error(e.code, e.message, null) }
            } catch (e: Exception) {
                runOnUiThread { result.error("io_error", e.message ?: e.toString(), null) }
            }
        }
    }

    private fun adapterOrThrow(): BluetoothAdapter {
        val adapter = BluetoothAdapter.getDefaultAdapter()
            ?: throw PrinterError("no_adapter", "本机没有蓝牙")
        if (!adapter.isEnabled) throw PrinterError("bluetooth_off", "蓝牙没打开")
        return adapter
    }

    private fun requirePermissions() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return

        val scan = ContextCompat.checkSelfPermission(
            this, Manifest.permission.BLUETOOTH_SCAN
        ) == PackageManager.PERMISSION_GRANTED
        val connect = ContextCompat.checkSelfPermission(
            this, Manifest.permission.BLUETOOTH_CONNECT
        ) == PackageManager.PERMISSION_GRANTED

        if (!scan || !connect) {
            runOnUiThread {
                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(
                        Manifest.permission.BLUETOOTH_SCAN,
                        Manifest.permission.BLUETOOTH_CONNECT,
                    ),
                    PERMISSION_REQUEST,
                )
            }
            throw PrinterError("permission_denied", "缺少蓝牙权限，请在系统弹窗里允许")
        }
    }

    /** 扫描 10 秒后返回「名称 + 地址」列表。 */
    private fun scanBlocking(): List<Map<String, String>> {
        val adapter = adapterOrThrow()
        requirePermissions()

        val found = LinkedHashMap<String, String>()
        val receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (intent?.action != BluetoothDevice.ACTION_FOUND) return
                val device: BluetoothDevice? =
                    intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
                if (device == null) return
                val name = try {
                    device.name
                } catch (e: SecurityException) {
                    null
                }
                found[device.address] = name ?: "未命名设备"
            }
        }

        val context = applicationContext
        context.registerReceiver(receiver, IntentFilter(BluetoothDevice.ACTION_FOUND))
        try {
            adapter.startDiscovery()
            val deadline = SystemClock.elapsedRealtime() + SCAN_WINDOW_MS
            while (SystemClock.elapsedRealtime() < deadline) {
                Thread.sleep(200)
            }
        } finally {
            try {
                adapter.cancelDiscovery()
            } catch (_: Exception) {
            }
            try {
                context.unregisterReceiver(receiver)
            } catch (_: Exception) {
            }
        }

        // 已配对的设备即使不在发现窗口里也应该能选。
        try {
            for (device in adapter.bondedDevices) {
                val name = try {
                    device.name
                } catch (e: SecurityException) {
                    null
                }
                found.putIfAbsent(device.address, name ?: "未命名设备")
            }
        } catch (_: Exception) {
        }

        return found.map { mapOf("name" to it.value, "address" to it.key) }
    }

    private fun connectBlocking(address: String?): Boolean {
        if (address.isNullOrBlank()) throw PrinterError("bad_address", "设备地址为空")
        val adapter = adapterOrThrow()
        requirePermissions()

        // 发现流程进行中建链会被系统直接拒绝，这是 SPP 最常见的连不上原因。
        try {
            adapter.cancelDiscovery()
        } catch (_: Exception) {
        }

        val device = try {
            adapter.getRemoteDevice(address)
        } catch (e: IllegalArgumentException) {
            throw PrinterError("bad_address", "设备地址无效：$address")
        }

        closeSocket()
        val newSocket = try {
            device.createRfcommSocketToServiceRecord(UUID.fromString(SPP_UUID))
        } catch (e: IOException) {
            throw PrinterError("socket_failed", "创建连接失败：${e.message}")
        }

        try {
            newSocket.connect()
        } catch (e: IOException) {
            try {
                newSocket.close()
            } catch (_: Exception) {
            }
            throw PrinterError("connect_failed", "连不上 ${device.address}，确认打印机已开机并在配对范围")
        }

        socket = newSocket
        return true
    }

    private fun writeBlocking(bytes: List<Int>?) {
        if (bytes == null || bytes.isEmpty()) throw PrinterError("empty_payload", "没有要发送的内容")
        val current = socket
        if (current == null || !current.isConnected) {
            throw PrinterError("not_connected", "还没连上打印机")
        }
        try {
            current.outputStream.write(bytes.map { it.toByte() }.toByteArray())
            current.outputStream.flush()
        } catch (e: IOException) {
            closeSocket()
            throw PrinterError("write_failed", "发送失败：${e.message}")
        }
    }

    private fun closeSocket() {
        val current = socket ?: return
        socket = null
        try {
            current.close()
        } catch (_: Exception) {
        }
    }

    private class PrinterError(val code: String, override val message: String) :
        Exception(message)
}
