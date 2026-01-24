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
        val android = project.extensions.findByName("android")
        if (android != null) {
            val namespace = android.javaClass.getMethod("getNamespace").invoke(android)
            if (namespace == null) {
                var packageName = project.group.toString()
                if (packageName == "null" || packageName == "") {
                    packageName = "com.example.${project.name.replace("-", "_")}"
                }
                android.javaClass.getMethod("setNamespace", String::class.java).invoke(android, packageName)
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
