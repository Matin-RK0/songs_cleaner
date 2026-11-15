import com.android.build.api.dsl.LibraryExtension

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
                namespace = group.toString().takeIf { it.isNotEmpty() }
                    ?: "app.legacy.${name.replace("-", "_")}"
            }

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
