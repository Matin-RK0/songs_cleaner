package com.example.songs_cleaner

import android.content.Context
import android.os.Build
import androidx.annotation.RequiresApi

/** Material roles from Android's dynamic palette, never from the wallpaper image. */
@RequiresApi(Build.VERSION_CODES.S)
internal object SystemColorRoles {
    fun read(context: Context, dark: Boolean): Map<String, Int> {
        val resources = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            namedRoles(dark)
        } else {
            tonalRoles(dark)
        }
        return resources.mapValues { (_, id) -> context.getColor(id) }
    }

    @RequiresApi(Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
    private fun namedRoles(dark: Boolean): Map<String, Int> {
        fun role(light: Int, night: Int) = if (dark) night else light
        return mapOf(
            "primary" to role(android.R.color.system_primary_light, android.R.color.system_primary_dark),
            "onPrimary" to role(android.R.color.system_on_primary_light, android.R.color.system_on_primary_dark),
            "primaryContainer" to role(android.R.color.system_primary_container_light, android.R.color.system_primary_container_dark),
            "onPrimaryContainer" to role(android.R.color.system_on_primary_container_light, android.R.color.system_on_primary_container_dark),
            "secondary" to role(android.R.color.system_secondary_light, android.R.color.system_secondary_dark),
            "onSecondary" to role(android.R.color.system_on_secondary_light, android.R.color.system_on_secondary_dark),
            "secondaryContainer" to role(android.R.color.system_secondary_container_light, android.R.color.system_secondary_container_dark),
            "onSecondaryContainer" to role(android.R.color.system_on_secondary_container_light, android.R.color.system_on_secondary_container_dark),
            "tertiary" to role(android.R.color.system_tertiary_light, android.R.color.system_tertiary_dark),
            "onTertiary" to role(android.R.color.system_on_tertiary_light, android.R.color.system_on_tertiary_dark),
            "tertiaryContainer" to role(android.R.color.system_tertiary_container_light, android.R.color.system_tertiary_container_dark),
            "onTertiaryContainer" to role(android.R.color.system_on_tertiary_container_light, android.R.color.system_on_tertiary_container_dark),
            "surface" to role(android.R.color.system_surface_light, android.R.color.system_surface_dark),
            "onSurface" to role(android.R.color.system_on_surface_light, android.R.color.system_on_surface_dark),
            "surfaceContainerLowest" to role(android.R.color.system_surface_container_lowest_light, android.R.color.system_surface_container_lowest_dark),
            "surfaceContainerLow" to role(android.R.color.system_surface_container_low_light, android.R.color.system_surface_container_low_dark),
            "surfaceContainer" to role(android.R.color.system_surface_container_light, android.R.color.system_surface_container_dark),
            "surfaceContainerHigh" to role(android.R.color.system_surface_container_high_light, android.R.color.system_surface_container_high_dark),
            "surfaceContainerHighest" to role(android.R.color.system_surface_container_highest_light, android.R.color.system_surface_container_highest_dark),
            "surfaceBright" to role(android.R.color.system_surface_bright_light, android.R.color.system_surface_bright_dark),
            "surfaceDim" to role(android.R.color.system_surface_dim_light, android.R.color.system_surface_dim_dark),
            "onSurfaceVariant" to role(android.R.color.system_on_surface_variant_light, android.R.color.system_on_surface_variant_dark),
            "outline" to role(android.R.color.system_outline_light, android.R.color.system_outline_dark),
            "outlineVariant" to role(android.R.color.system_outline_variant_light, android.R.color.system_outline_variant_dark),
            "inverseSurface" to role(android.R.color.system_neutral1_800, android.R.color.system_neutral1_100),
            "onInverseSurface" to role(android.R.color.system_neutral1_50, android.R.color.system_neutral1_800),
            "inversePrimary" to role(android.R.color.system_primary_dark, android.R.color.system_primary_light),
            "error" to role(android.R.color.system_error_light, android.R.color.system_error_dark),
            "onError" to role(android.R.color.system_on_error_light, android.R.color.system_on_error_dark),
            "errorContainer" to role(android.R.color.system_error_container_light, android.R.color.system_error_container_dark),
            "onErrorContainer" to role(android.R.color.system_on_error_container_light, android.R.color.system_on_error_container_dark),
        )
    }

    private fun tonalRoles(dark: Boolean): Map<String, Int> {
        fun role(light: Int, night: Int) = if (dark) night else light
        return mapOf(
            "primary" to role(android.R.color.system_accent1_600, android.R.color.system_accent1_200),
            "onPrimary" to role(android.R.color.system_accent1_0, android.R.color.system_accent1_800),
            "primaryContainer" to role(android.R.color.system_accent1_100, android.R.color.system_accent1_700),
            "onPrimaryContainer" to role(android.R.color.system_accent1_900, android.R.color.system_accent1_100),
            "secondary" to role(android.R.color.system_accent2_600, android.R.color.system_accent2_200),
            "onSecondary" to role(android.R.color.system_accent2_0, android.R.color.system_accent2_800),
            "secondaryContainer" to role(android.R.color.system_accent2_100, android.R.color.system_accent2_700),
            "onSecondaryContainer" to role(android.R.color.system_accent2_900, android.R.color.system_accent2_100),
            "tertiary" to role(android.R.color.system_accent3_600, android.R.color.system_accent3_200),
            "onTertiary" to role(android.R.color.system_accent3_0, android.R.color.system_accent3_800),
            "tertiaryContainer" to role(android.R.color.system_accent3_100, android.R.color.system_accent3_700),
            "onTertiaryContainer" to role(android.R.color.system_accent3_900, android.R.color.system_accent3_100),
            "surface" to role(android.R.color.system_neutral1_10, android.R.color.system_neutral1_900),
            "onSurface" to role(android.R.color.system_neutral1_900, android.R.color.system_neutral1_100),
            "surfaceContainerLowest" to role(android.R.color.system_neutral1_0, android.R.color.system_neutral1_1000),
            "surfaceContainerLow" to role(android.R.color.system_neutral1_10, android.R.color.system_neutral1_900),
            "surfaceContainer" to role(android.R.color.system_neutral1_50, android.R.color.system_neutral1_900),
            "surfaceContainerHigh" to role(android.R.color.system_neutral1_50, android.R.color.system_neutral1_800),
            "surfaceContainerHighest" to role(android.R.color.system_neutral1_100, android.R.color.system_neutral1_800),
            "surfaceBright" to role(android.R.color.system_neutral1_10, android.R.color.system_neutral1_800),
            "surfaceDim" to role(android.R.color.system_neutral1_200, android.R.color.system_neutral1_900),
            "onSurfaceVariant" to role(android.R.color.system_neutral2_700, android.R.color.system_neutral2_200),
            "outline" to role(android.R.color.system_neutral2_500, android.R.color.system_neutral2_400),
            "outlineVariant" to role(android.R.color.system_neutral2_200, android.R.color.system_neutral2_700),
            "inverseSurface" to role(android.R.color.system_neutral1_800, android.R.color.system_neutral1_100),
            "onInverseSurface" to role(android.R.color.system_neutral1_50, android.R.color.system_neutral1_800),
            "inversePrimary" to role(android.R.color.system_accent1_200, android.R.color.system_accent1_600),
        )
    }
}
