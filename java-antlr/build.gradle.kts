plugins {
    java
    application
    antlr
}

repositories { mavenCentral() }

dependencies {
    antlr("org.antlr:antlr4:4.13.2")
    testImplementation(platform("org.junit:junit-bom:5.12.2"))
    testImplementation("org.junit.jupiter:junit-jupiter")
    testRuntimeOnly("org.junit.platform:junit-platform-launcher")
}

application {
    mainClass = "Main"
}

tasks.generateGrammarSource {
    arguments = arguments + listOf("-visitor")
}

tasks.named<JavaExec>("run") {
    standardInput = System.`in`
}

tasks.test {
    useJUnitPlatform()
}
