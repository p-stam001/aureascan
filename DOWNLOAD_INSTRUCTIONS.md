# Manual Download Instructions for Gradle Kotlin DSL Plugin

## Files to Download

You need to download the following files manually:

### 1. Plugin Marker POM File
**URL:** `https://plugins.gradle.org/m2/org/gradle/kotlin/kotlin-dsl/org.gradle.kotlin.kotlin-dsl.gradle.plugin/5.1.2/org.gradle.kotlin.kotlin-dsl.gradle.plugin-5.1.2.pom`

**Save as:** `org.gradle.kotlin.kotlin-dsl.gradle.plugin-5.1.2.pom`

### 2. Plugin Marker JAR File  
**URL:** `https://plugins.gradle.org/m2/org/gradle/kotlin/kotlin-dsl/org.gradle.kotlin.kotlin-dsl.gradle.plugin/5.1.2/org.gradle.kotlin.kotlin-dsl.gradle.plugin-5.1.2.jar`

**Save as:** `org.gradle.kotlin.kotlin-dsl.gradle.plugin-5.1.2.jar`

### 3. Actual Plugin POM File
**URL:** `https://repo1.maven.org/maven2/org/gradle/kotlin/gradle-kotlin-dsl-plugins/5.1.2/gradle-kotlin-dsl-plugins-5.1.2.pom`

**Save as:** `gradle-kotlin-dsl-plugins-5.1.2.pom`

### 4. Actual Plugin JAR File
**URL:** `https://repo1.maven.org/maven2/org/gradle/kotlin/gradle-kotlin-dsl-plugins/5.1.2/gradle-kotlin-dsl-plugins-5.1.2.jar`

**Save as:** `gradle-kotlin-dsl-plugins-5.1.2.jar`

## Where to Place the Files

### Step 1: Create the directory structure

Create these directories in your Gradle cache:

**Windows Path:** `C:\Users\1\.gradle\caches\modules-2\files-2.1\`

1. For Plugin Marker:
   ```
   C:\Users\1\.gradle\caches\modules-2\files-2.1\org.gradle.kotlin.kotlin-dsl\org.gradle.kotlin.kotlin-dsl.gradle.plugin\5.1.2\[HASH]\
   ```

2. For Actual Plugin:
   ```
   C:\Users\1\.gradle\caches\modules-2\files-2.1\org.gradle.kotlin\gradle-kotlin-dsl-plugins\5.1.2\[HASH]\
   ```

### Step 2: Calculate the hash directories

Gradle uses SHA1 hashes of the artifact coordinates. However, we can let Gradle create the hash directories automatically.

## Easier Method: Use Gradle's Plugin Cache Structure

Actually, a simpler approach is to place files in the plugin cache directory structure that Gradle will recognize.

### Alternative: Place in plugin metadata cache

Place the plugin marker files here:
```
C:\Users\1\.gradle\caches\modules-2\metadata-2.96\descriptors\org.gradle.kotlin.kotlin-dsl\org.gradle.kotlin.kotlin-dsl.gradle.plugin\5.1.2\
```

But this is complex. Let me provide a script to help.



