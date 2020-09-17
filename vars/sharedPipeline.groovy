def call(body = {}) {

  def pipelineParams= [:]
  body.resolveStrategy = Closure.DELEGATE_FIRST
  body.delegate = pipelineParams
  body()

  node('sdk-agents') {
    ansiColor('xterm') {
      try {
        checkout scm

        stage('Build then test') {
          runSteps(pipelineParams.preBuildSteps)
          sh 'bundle install --path vendor/bundle'
          sh 'bundle exec fastlane ci'
        }

        stage('Archive artifacts') {
          archiveArtifacts allowEmptyArchive: true, artifacts: 'artifacts/**/*'
          runSteps(pipelineParams.additionalArchiveSteps)
        }

        (pipelineParams.additionalStages ?: []).each { it.call() }

        runSteps(pipelineParams.additionalSuccessSteps)

      } catch (e) {
        currentBuild.result = 'FAILURE'
        runSteps(pipelineParams.additionalFailureSteps)

        // re-throwing
        throw e
      } finally { 
        def currentResult = currentBuild.currentResult
        def previousResult = currentBuild.getPreviousBuild()?.result

        if (previousResult != currentResult) {

          if (previousResult != null && currentResult == 'SUCCESS') {
            notifySlackFixed()

          } else if (previousResult == 'SUCCESS') {
            notifySlackRegression()
          }
        }
      }
    }
  }
}

def runSteps(steps) {
  (steps ?: []).each { it.call() }
}
