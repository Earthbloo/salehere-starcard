package co.salehere.starcard.ui

import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import co.salehere.starcard.AppContext

/** สั่นตอบสนอง (= `Haptics` ใน CardScreen.swift) — `UIImpactFeedbackGenerator` ของ iOS */
object Haptics {
    enum class Style { light, medium, heavy, rigid, soft }

    private val vibrator: Vibrator? by lazy {
        val app = AppContext.app
        if (Build.VERSION.SDK_INT >= 31) {
            (app.getSystemService(android.content.Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager)?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            app.getSystemService(android.content.Context.VIBRATOR_SERVICE) as? Vibrator
        }
    }

    fun impact(style: Style = Style.medium) {
        val v = vibrator ?: return
        if (!v.hasVibrator()) return
        val effect = if (Build.VERSION.SDK_INT >= 29) {
            when (style) {
                Style.light, Style.soft -> VibrationEffect.createPredefined(VibrationEffect.EFFECT_TICK)
                Style.medium -> VibrationEffect.createPredefined(VibrationEffect.EFFECT_CLICK)
                Style.heavy, Style.rigid -> VibrationEffect.createPredefined(VibrationEffect.EFFECT_HEAVY_CLICK)
            }
        } else {
            VibrationEffect.createOneShot(if (style == Style.light) 8 else 14, VibrationEffect.DEFAULT_AMPLITUDE)
        }
        runCatching { v.vibrate(effect) }
    }

    fun rigid() = impact(Style.rigid)
    fun light() = impact(Style.light)
    fun medium() = impact(Style.medium)
}
