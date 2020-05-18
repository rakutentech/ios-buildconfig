def call(String reportPath) {
    cobertura(
        coberturaReportFile: reportPath, 
        enableNewApi: true, 
        methodCoverageTargets: '80.0, 0.0, 0.0', 
        lineCoverageTargets: '80.0, 0.0, 0.0', 
        conditionalCoverageTargets: '70.0, 0.0, 0.0'
    )
}