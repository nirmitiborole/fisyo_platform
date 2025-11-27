package com.example.goniometer

import android.content.Context
import android.content.res.AssetManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import org.tensorflow.lite.Interpreter
import java.io.FileInputStream
import java.io.IOException
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.channels.FileChannel

class MotionDetectorPlugin: FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var interpreter: Interpreter? = null

    // Scaler parameters from your Python training code
    private val scalerMean = floatArrayOf(
        2.6406200085561724f, -0.11344833115984997f, -6.206733349299058f, 0.004916666586262484f, -0.03788500039962431f, 0.010943333675463995f
    )
    private val scalerScale = floatArrayOf(
        3.6191826010638826f, 3.9051673493009726f, 4.765696040089f, 0.31691406760709817f, 0.4857879983324985f, 0.3500801464656341f
    )

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        // This is the correct way to get the context and set up the channel
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "motion_detector")
        channel.setMethodCallHandler(this)
    }

    // The rest of the onMethodCall, initializeModel, predictMotion, etc. methods...
    // They are correct, but I'll omit them here for brevity.

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initializeModel" -> {
                initializeModel(result)
            }
            "predictMotion" -> {
                val sensorData = call.argument<List<Double>>("sensorData")
                if (sensorData != null && sensorData.size == 6) {
                    predictMotion(sensorData.map { it.toFloat() }.toFloatArray(), result)
                } else {
                    result.error("INVALID_DATA", "Sensor data must contain exactly 6 values", null)
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun initializeModel(result: Result) {
        try {
            val modelBuffer = loadModelFile()
            interpreter = Interpreter(modelBuffer)
            result.success("Model initialized successfully")
        } catch (e: Exception) {
            result.error("MODEL_INIT_ERROR", "Failed to initialize model: ${e.message}", null)
        }
    }

    @Throws(IOException::class)
    private fun loadModelFile(): ByteBuffer {
        val assets: AssetManager = context.assets
        val fileDescriptor = assets.openFd("movement_model.tflite")
        val inputStream = FileInputStream(fileDescriptor.fileDescriptor)
        val fileChannel = inputStream.channel
        val startOffset = fileDescriptor.startOffset
        val declaredLength = fileDescriptor.declaredLength

        val modelBuffer = fileChannel.map(FileChannel.MapMode.READ_ONLY, startOffset, declaredLength)
        return modelBuffer
    }

    private fun normalizeInput(input: FloatArray): FloatArray {
        val normalized = FloatArray(6)
        for (i in input.indices) {
            normalized[i] = (input[i] - scalerMean[i]) / scalerScale[i]
        }
        return normalized
    }

    private fun predictMotion(sensorData: FloatArray, result: Result) {
        if (interpreter == null) {
            result.error("MODEL_NOT_INITIALIZED", "Model not initialized", null)
            return
        }

        try {
            val normalizedData = normalizeInput(sensorData)

            val inputBuffer = ByteBuffer.allocateDirect(6 * 4)
            inputBuffer.order(ByteOrder.nativeOrder())
            for (value in normalizedData) {
                inputBuffer.putFloat(value)
            }

            val outputBuffer = ByteBuffer.allocateDirect(2 * 4)
            outputBuffer.order(ByteOrder.nativeOrder())

            interpreter?.run(inputBuffer, outputBuffer)

            outputBuffer.rewind()
            val stillProbability = outputBuffer.float
            val movingProbability = outputBuffer.float

            val isMoving = movingProbability > stillProbability

            val resultMap = mapOf(
                "probabilities" to listOf(stillProbability, movingProbability),
                "isMoving" to isMoving,
                "confidence" to if (isMoving) movingProbability else stillProbability
            )

            result.success(resultMap)

        } catch (e: Exception) {
            result.error("PREDICTION_ERROR", "Failed to predict motion: ${e.message}", null)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        interpreter?.close()
        interpreter = null
    }
}