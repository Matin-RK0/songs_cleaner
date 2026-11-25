package com.example.songs_cleaner

import android.app.Activity
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.ImageDecoder
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.content.ActivityNotFoundException
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException
import kotlin.math.roundToInt

/** Copies a bounded image into app storage; the original URI is not retained. */
internal class LocalImagePicker(
    private val activity: Activity,
    private val requestCode: Int,
    private val folder: String,
    private val maxEdge: Int,
    private val preferPhotoPicker: Boolean = false,
) {
    private var pending: MethodChannel.Result? = null

    fun pick(result: MethodChannel.Result) {
        if (pending != null) {
            result.error("COVER_PICKER_BUSY", null, null)
            return
        }
        pending = result
        try {
            openPicker()
        } catch (_: Exception) {
            pending = null
            result.error("COVER_PICK_FAILED", null, null)
        }
    }

    private fun openPicker() {
        if (preferPhotoPicker && Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            try {
                activity.startActivityForResult(Intent(MediaStore.ACTION_PICK_IMAGES).setType("image/*"), requestCode)
                return
            } catch (_: ActivityNotFoundException) {
                // Some devices do not supply the system Photo Picker.
            }
        }
        activity.startActivityForResult(Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "image/*"
        }, requestCode)
    }

    fun handleResult(requestCode: Int, resultCode: Int, uri: Uri?): Boolean {
        if (requestCode != this.requestCode) return false
        val result = pending ?: return true
        if (resultCode != Activity.RESULT_OK || uri == null) {
            pending = null
            result.success(null)
            return true
        }
        val context = activity.applicationContext
        Thread {
            var target: File? = null
            try {
                val bitmap = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    val source = ImageDecoder.createSource(context.contentResolver, uri)
                    ImageDecoder.decodeBitmap(source) { decoder, info, _ ->
                        val size = info.size
                        val scale = minOf(1.0, maxEdge.toDouble() / maxOf(size.width, size.height))
                        decoder.setTargetSize(
                            (size.width * scale).roundToInt().coerceAtLeast(1),
                            (size.height * scale).roundToInt().coerceAtLeast(1),
                        )
                        decoder.allocator = ImageDecoder.ALLOCATOR_SOFTWARE
                    }
                } else {
                    val options = BitmapFactory.Options().apply { inJustDecodeBounds = true }
                    context.contentResolver.openInputStream(uri)?.use {
                        BitmapFactory.decodeStream(it, null, options)
                    }
                    if (options.outWidth <= 0 || options.outHeight <= 0) throw IOException()
                    var sample = 1
                    while (maxOf(options.outWidth, options.outHeight) / sample > maxEdge) sample *= 2
                    options.inJustDecodeBounds = false
                    options.inSampleSize = sample
                    context.contentResolver.openInputStream(uri)?.use {
                        BitmapFactory.decodeStream(it, null, options)
                    } ?: throw IOException()
                }
                try {
                    val dir = File(context.filesDir, folder)
                    if (!dir.isDirectory && !dir.mkdirs()) throw IOException()
                    target = File.createTempFile("image-", ".jpg", dir)
                    target.outputStream().use {
                        if (!bitmap.compress(Bitmap.CompressFormat.JPEG, 86, it)) throw IOException()
                    }
                } finally {
                    bitmap.recycle()
                }
                val cover = requireNotNull(target)
                activity.runOnUiThread {
                    if (pending === result) {
                        pending = null
                        result.success(cover.absolutePath)
                    } else {
                        cover.delete()
                    }
                }
            } catch (_: Exception) {
                target?.delete()
                activity.runOnUiThread {
                    if (pending === result) {
                        pending = null
                        result.error("COVER_READ_FAILED", null, null)
                    }
                }
            }
        }.start()
        return true
    }

    fun dispose() {
        pending?.success(null)
        pending = null
    }

}
