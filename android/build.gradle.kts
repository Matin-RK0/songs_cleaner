import com.android.build.api.dsl.LibraryExtension
import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

// Legacy plugins (on_audio_query_android) predate the required AGP
// namespace declaration. Inject it before Android variants are created.
val legacyPluginNamespaces = mapOf(
    "on_audio_query_android" to "com.lucasjosino.on_audio_query",
)

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    afterEvaluate {
        if (!pluginManager.hasPlugin("com.android.library")) return@afterEvaluate
        extensions.configure<LibraryExtension>("android") {
            val current = namespace
            if (current == null || current.isEmpty()) {
                namespace = legacyPluginNamespaces[name]
                    ?: group.toString().takeIf { it.isNotEmpty() }
                    ?: "app.legacy.${name.replace("-", "_")}"
            }

            // on_audio_query_android 1.1.0 still uses the legacy Android and
            // Kotlin Gradle plugins. Keep its Java and Kotlin bytecode targets
            // aligned without changing the application's Java 17 target.
            if (name == "on_audio_query_android") {
                // The plugin hard-codes compileSdk 33, but its resolved AndroidX
                // dependencies require at least API 34. Match Flutter's API 36.
                compileSdk = 36
                compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_11
                    targetCompatibility = JavaVersion.VERSION_11
                }
            }
        }
    }
}

subprojects {
    if (name == "on_audio_query_android") {
        tasks.withType<KotlinCompile>().configureEach {
            compilerOptions.jvmTarget.set(JvmTarget.JVM_11)
        }
    }
}

// Must stay after the afterEvaluate registration above so that forcing
// the app evaluation does not skip the namespace injection.
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
